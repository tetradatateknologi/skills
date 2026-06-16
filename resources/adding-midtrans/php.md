# Midtrans — PHP

Official SDK: [midtrans-php](https://github.com/Midtrans/midtrans-php)

## Install

```bash
composer require midtrans/midtrans-php
```

Laravel: run `composer dump-autoload` if the class is not found.

## Config

Create a config module (e.g. `config/midtrans.php` or bootstrap in a service provider):

```php
<?php

\Midtrans\Config::$serverKey = env('MIDTRANS_SERVER_KEY');
\Midtrans\Config::$isProduction = env('MIDTRANS_IS_PRODUCTION', false);
\Midtrans\Config::$isSanitized = true;
\Midtrans\Config::$is3ds = true;
```

Laravel `.env`:

```
MIDTRANS_SERVER_KEY=SB-Mid-server-...
MIDTRANS_CLIENT_KEY=SB-Mid-client-...
MIDTRANS_IS_PRODUCTION=false
```

## Snap Redirect (default)

```php
$params = [
    'transaction_details' => [
        'order_id' => $order->order_id,      // from your DB
        'gross_amount' => (int) $order->amount,
    ],
    'customer_details' => [
        'first_name' => $order->customer_name,
        'email' => $order->customer_email,
        'phone' => $order->customer_phone,
    ],
    'item_details' => [
        [
            'id' => $order->product_id,
            'price' => (int) $order->amount,
            'quantity' => 1,
            'name' => $order->product_name,
        ],
    ],
];

try {
    $snap = \Midtrans\Snap::createTransaction($params);
    return redirect($snap->redirect_url);
} catch (\Exception $e) {
    // handle error
}
```

## Snap popup (token)

```php
$snapToken = \Midtrans\Snap::getSnapToken($params);
// Return token to frontend; call snap.pay($snapToken) via snap.js
return response()->json(['snap_token' => $snapToken]);
```

## Core API charge (custom UI)

```php
$params = [
    'payment_type' => 'credit_card',
    'transaction_details' => [
        'order_id' => $order->order_id,
        'gross_amount' => (int) $order->amount,
    ],
    'credit_card' => [
        'token_id' => $request->token_id,  // from Midtrans JS on frontend
        'authentication' => true,
    ],
];

$response = \Midtrans\CoreApi::charge($params);
// Handle 3DS: redirect user to $response->redirect_url if present
```

## Notification handler

Create `POST /payments/midtrans/notification`:

```php
public function handleNotification(Request $request)
{
    $notif = new \Midtrans\Notification();

    $orderId = $notif->order_id;
    $transaction = $notif->transaction_status;
    $fraud = $notif->fraud_status;

    // Always verify via API — do not trust payload alone
    $status = \Midtrans\Transaction::status($orderId);

    $order = Order::where('order_id', $orderId)->firstOrFail();

    if ($status->transaction_status === 'capture') {
        if ($status->fraud_status === 'accept') {
            $order->markAsPaid(); // idempotent
        } elseif ($status->fraud_status === 'challenge') {
            $order->markAsReviewRequired();
        }
    } elseif ($status->transaction_status === 'settlement') {
        $order->markAsPaid();
    } elseif (in_array($status->transaction_status, ['deny', 'cancel', 'expire'])) {
        $order->markAsFailed();
    } elseif ($status->transaction_status === 'pending') {
        $order->markAsPending();
    }

    return response('OK', 200);
}
```

Laravel route:

```php
Route::post('/payments/midtrans/notification', [PaymentController::class, 'handleNotification'])
    ->withoutMiddleware([\App\Http\Middleware\VerifyCsrfToken::class]);
```

## Transaction lifecycle (if requested)

```php
// Check status
$status = \Midtrans\Transaction::status($orderId);

// Approve challenged credit card transaction
\Midtrans\Transaction::approve($orderId);

// Cancel pending or challenged transaction
\Midtrans\Transaction::cancel($orderId);

// Expire pending transaction
\Midtrans\Transaction::expire($orderId);

// Refund settled transaction
\Midtrans\Transaction::refund($orderId, [
    'refund_key' => 'refund-' . $orderId,
    'amount' => 10000,
    'reason' => 'Item out of stock',
]);
```

## Laravel conventions

- Put config in `config/midtrans.php`, load keys via `config('midtrans.server_key')`.
- Use a `MidtransService` or `PaymentGateway` interface if the project already abstracts payments.
- Store `order_id`, `amount`, and `payment_status` on the orders table.
- Exclude the notification route from CSRF middleware.
- Queue side effects (email, stock) after status is confirmed paid.
