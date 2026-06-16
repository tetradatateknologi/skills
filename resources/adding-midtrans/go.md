# Midtrans — Go

Official SDK: [midtrans-go](https://github.com/Midtrans/midtrans-go)

## Install

```bash
go get -u github.com/midtrans/midtrans-go
```

```go
import (
    "github.com/midtrans/midtrans-go"
    "github.com/midtrans/midtrans-go/coreapi"
    "github.com/midtrans/midtrans-go/snap"
)
```

## Config

```go
func newSnapClient() snap.Client {
    var s snap.Client
    env := midtrans.Sandbox
    if os.Getenv("MIDTRANS_IS_PRODUCTION") == "true" {
        env = midtrans.Production
    }
    s.New(os.Getenv("MIDTRANS_SERVER_KEY"), env)
    return s
}
```

Environment variables:

```
MIDTRANS_SERVER_KEY=SB-Mid-server-...
MIDTRANS_CLIENT_KEY=SB-Mid-client-...
MIDTRANS_IS_PRODUCTION=false
```

## Snap Redirect (default)

```go
func createPayment(w http.ResponseWriter, r *http.Request) {
    s := newSnapClient()

    req := &snap.Request{
        TransactionDetails: midtrans.TransactionDetails{
            OrderID:  order.ID,
            GrossAmt: order.Amount,
        },
        CustomerDetail: &midtrans.CustomerDetails{
            FName: order.CustomerName,
            Email: order.CustomerEmail,
            Phone: order.CustomerPhone,
        },
        CreditCard: &snap.CreditCardDetails{Secure: true},
    }

    snapResp, err := s.CreateTransaction(req)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    http.Redirect(w, r, snapResp.RedirectURL, http.StatusFound)
}
```

## Snap popup (token)

```go
token, err := s.CreateTransactionToken(req)
// Return JSON { "snap_token": token } to frontend; call snap.pay(token) via snap.js
```

## Core API charge (custom UI)

```go
func chargeCard(w http.ResponseWriter, r *http.Request) {
    c := coreapi.Client{}
    c.New(os.Getenv("MIDTRANS_SERVER_KEY"), midtrans.Sandbox)

    chargeReq := &coreapi.ChargeReq{
        PaymentType: coreapi.PaymentTypeCreditCard,
        TransactionDetails: midtrans.TransactionDetails{
            OrderID:  order.ID,
            GrossAmt: order.Amount,
        },
        CreditCard: &coreapi.CreditCardDetails{
            TokenID:        tokenID,
            Authentication: true,
        },
    }

    res, err := c.ChargeTransaction(chargeReq)
    // Handle 3DS: redirect user to res.RedirectURL if present
}
```

## Notification handler

Create `POST /payments/midtrans/notification`:

```go
func handleNotification(w http.ResponseWriter, r *http.Request) {
    var payload map[string]interface{}
    if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
        http.Error(w, "invalid payload", http.StatusBadRequest)
        return
    }

    orderID, ok := payload["order_id"].(string)
    if !ok {
        http.Error(w, "missing order_id", http.StatusBadRequest)
        return
    }

    c := coreapi.Client{}
    c.New(os.Getenv("MIDTRANS_SERVER_KEY"), midtransEnv())

    // Always verify via API — do not trust payload alone
    status, err := c.CheckTransaction(orderID)
    if err != nil {
        http.Error(w, err.GetMessage(), http.StatusInternalServerError)
        return
    }

    switch status.TransactionStatus {
    case "capture":
        if status.FraudStatus == "accept" {
            markOrderPaid(orderID)
        } else if status.FraudStatus == "challenge" {
            markOrderReviewRequired(orderID)
        }
    case "settlement":
        markOrderPaid(orderID)
    case "deny", "cancel", "expire":
        markOrderFailed(orderID)
    case "pending":
        markOrderPending(orderID)
    }

    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"status":"ok"}`))
}
```

Register the route without auth middleware — Midtrans sends unsigned POST requests.

## Transaction lifecycle (if requested)

```go
c := coreapi.Client{}
c.New(os.Getenv("MIDTRANS_SERVER_KEY"), midtransEnv())

// Check status
status, _ := c.CheckTransaction(orderID)

// Approve challenged credit card transaction
c.ApproveTransaction(orderID)

// Cancel pending or challenged transaction
c.CancelTransaction(orderID)

// Expire pending transaction
c.ExpireTransaction(orderID)

// Refund settled transaction
c.RefundTransaction(orderID, &coreapi.RefundReq{
    RefundKey: "refund-" + orderID,
    Amount:    10000,
    Reason:    "Item out of stock",
})
```

## Iris disbursement (only if requested)

Iris uses a **separate API key** from the payment gateway. Do not mix Iris and Snap/Core API credentials.

```go
import "github.com/midtrans/midtrans-go/iris"

var i iris.Client
i.New(os.Getenv("MIDTRANS_IRIS_API_KEY"), midtrans.Sandbox)

// List supported banks
banks, _ := i.GetBeneficiaryBanks()

// Create payout
payout, _ := i.CreatePayout(iris.CreatePayoutReq{
    // see iris package types and https://iris-docs.midtrans.com
})
```

## Go conventions

- Wrap Midtrans client in a `PaymentService` struct; inject via constructor.
- Use `context.Context` via `c.Options.SetContext(ctx)` for request timeouts.
- Set idempotency key on charge: `c.Options.SetIdempotencyKey(uniqueID)`.
- Return `200` quickly from the notification handler; process side effects asynchronously if heavy.
- Match existing router patterns (Gin, Echo, chi, stdlib `http.ServeMux`).
