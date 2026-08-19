import crypto from 'node:crypto';
import express from 'express';
import 'dotenv/config';

const app = express();
app.use(express.json({ limit: '64kb' }));

const PORT = Number(process.env.PORT || 8787);
const XENDIT_SECRET_KEY = process.env.XENDIT_SECRET_KEY || '';
const XENDIT_WEBHOOK_TOKEN = process.env.XENDIT_WEBHOOK_TOKEN || '';
const NOWPAYMENTS_API_KEY = process.env.NOWPAYMENTS_API_KEY || '';
const NOWPAYMENTS_IPN_SECRET = process.env.NOWPAYMENTS_IPN_SECRET || '';
const PUBLIC_BASE_URL = process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`;

const PRICES = Object.freeze({
  premium_monthly: { amount: 79000, durationDays: 30 },
  lifetime: { amount: 799000, durationDays: null },
});

function orderId() {
  return `JS-${Date.now()}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
}

app.get('/health', (_req, res) => res.json({ ok: true, service: 'japanese-study-payment-api' }));

app.post('/v1/payments/checkout', async (req, res) => {
  const { plan_id, amount, user_email, provider, price_version } = req.body || {};
  const plan = PRICES[plan_id];
  if (!plan || Number(amount) !== plan.amount || !user_email || !provider) {
    return res.status(400).json({ error: 'Invalid payment request.' });
  }
  const id = orderId();

  if (provider === 'xendit') {
    if (!XENDIT_SECRET_KEY) return res.status(503).json({ error: 'Xendit not configured.' });
    const auth = Buffer.from(`${XENDIT_SECRET_KEY}:`).toString('base64');
    const payload = {
      reference_id: id,
      session_type: 'PAY',
      mode: 'PAYMENT_LINK',
      amount: plan.amount,
      currency: 'IDR',
      country: 'ID',
      description: `Japanese Study ${plan_id}`,
      success_return_url: `${PUBLIC_BASE_URL}/payment/success?order_id=${encodeURIComponent(id)}`,
      cancel_return_url: `${PUBLIC_BASE_URL}/payment/cancel?order_id=${encodeURIComponent(id)}`,
      customer: { reference_id: `js-${crypto.createHash('sha256').update(user_email).digest('hex').slice(0, 24)}`, type: 'INDIVIDUAL', email: user_email },
      metadata: { plan_id, price_version: String(price_version ?? 0), user_email },
    };
    const r = await fetch('https://api.xendit.co/sessions', {
      method: 'POST',
      headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await r.json();
    if (!r.ok) return res.status(502).json({ error: data?.message || 'Xendit session creation failed.' });
    return res.json({ order_id: id, provider: 'xendit', status: data.status || 'created', checkout_url: data.payment_link_url || data.checkout_url });
  }

  if (provider === 'nowpayments') {
    if (!NOWPAYMENTS_API_KEY) return res.status(503).json({ error: 'NOWPayments not configured.' });
    const r = await fetch('https://api.nowpayments.io/v1/payment', {
      method: 'POST',
      headers: { 'x-api-key': NOWPAYMENTS_API_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ price_amount: plan.amount, price_currency: 'idr', order_id: id, order_description: `Japanese Study ${plan_id}`, ipn_callback_url: `${PUBLIC_BASE_URL}/v1/webhooks/nowpayments`, success_url: `${PUBLIC_BASE_URL}/payment/success?order_id=${encodeURIComponent(id)}`, cancel_url: `${PUBLIC_BASE_URL}/payment/cancel?order_id=${encodeURIComponent(id)}` }),
    });
    const data = await r.json();
    if (!r.ok) return res.status(502).json({ error: data?.message || 'NOWPayments payment creation failed.' });
    return res.json({ order_id: id, provider: 'nowpayments', status: data.payment_status || 'waiting', checkout_url: data.pay_address ? `https://nowpayments.io/payment/?iid=${encodeURIComponent(data.payment_id)}` : data.invoice_url || data.payin_extra_id || '' });
  }

  return res.status(400).json({ error: 'Unsupported provider.' });
});

app.post('/v1/webhooks/xendit', (req, res) => {
  const token = req.header('x-callback-token') || '';
  if (!XENDIT_WEBHOOK_TOKEN || token !== XENDIT_WEBHOOK_TOKEN) return res.status(401).json({ error: 'invalid webhook token' });
  // IMPORTANT: persist the event in your DB, make activation idempotent, then grant entitlement.
  console.log('Xendit webhook', JSON.stringify(req.body));
  return res.status(204).end();
});

app.post('/v1/webhooks/nowpayments', (req, res) => {
  const signature = req.header('x-nowpayments-sig') || '';
  if (NOWPAYMENTS_IPN_SECRET) {
    const body = JSON.stringify(req.body);
    const expected = crypto.createHmac('sha512', NOWPAYMENTS_IPN_SECRET).update(body).digest('hex');
    if (signature !== expected) return res.status(401).json({ error: 'invalid IPN signature' });
  }
  // IMPORTANT: persist the event in your DB and grant entitlement idempotently after confirmed payment.
  console.log('NOWPayments IPN', JSON.stringify(req.body));
  return res.status(204).end();
});

app.get('/payment/success', (_req, res) => res.send('Pembayaran diterima. Kembali ke aplikasi Japanese Study.'));
app.get('/payment/cancel', (_req, res) => res.send('Pembayaran dibatalkan.'));

app.listen(PORT, () => console.log(`Japanese Study payment API listening on :${PORT}`));
