// Stripe → RedTrack conversion webhook
// Deployed at /api/stripe-webhook on Vercel
// Triggered by Stripe on checkout.session.completed

import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
const REDTRACK_DOMAIN = process.env.REDTRACK_DOMAIN; // e.g. "track-xxxxx.rdtk.io"

export const config = {
  api: { bodyParser: false }, // required for raw body signature verification
};

async function buffer(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
  }
  return Buffer.concat(chunks);
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const sig = req.headers['stripe-signature'];
  const rawBody = await buffer(req);

  let event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('[stripe-webhook] signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const clickId = session.client_reference_id;
    const amount = session.amount_total != null ? (session.amount_total / 100).toFixed(2) : '0.00';
    const txId = session.id;
    const currency = (session.currency || 'usd').toLowerCase();

    console.log('[stripe-webhook] checkout.session.completed', {
      txId,
      clickId: clickId || '(none)',
      amount,
      currency,
    });

    if (clickId && REDTRACK_DOMAIN) {
      const url = `https://${REDTRACK_DOMAIN}/postback?clickid=${encodeURIComponent(clickId)}&sum=${amount}&currency=${currency}&txid=${encodeURIComponent(txId)}&status=sale&type=purchase`;
      try {
        const r = await fetch(url);
        console.log('[stripe-webhook] RedTrack postback →', r.status, url);
      } catch (err) {
        console.error('[stripe-webhook] RedTrack postback error:', err);
      }
    } else if (!clickId) {
      console.warn('[stripe-webhook] No client_reference_id (organic sale?)', txId);
    } else {
      console.warn('[stripe-webhook] REDTRACK_DOMAIN env var not set');
    }
  }

  return res.status(200).json({ received: true });
}
