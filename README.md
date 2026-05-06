# Crave-Off Funnel

CNN-style advertorial → 30-second quiz → personalized result → checkout with 3 packs.

## Structure

- `index.html` — advertorial (Health & Wellness Daily)
- `quiz.html` — 6-question, 30-second metabolism assessment
- `result.html` — 94% match result + confetti + product card
- `checkout.html` — 3 packs (1/2/3 bottles) + order bump + Stripe links
- `img/` — product + before/after images

## Deploy

1. Create GitHub repo: `123playamazon-boop/craveoff`
2. Import to Vercel (auto-deploys on push to `main`)
3. Replace `REPLACE_STRIPE_LINK_1PACK`, `_2PACK`, `_3PACK` in `checkout.html` with real Stripe Payment Links

## Stripe Placeholders (to replace)

- 1 Bottle: `REPLACE_STRIPE_LINK_1PACK`
- 2 Bottles: `REPLACE_STRIPE_LINK_2PACK`
- 3 Bottles: `REPLACE_STRIPE_LINK_3PACK`

## Images Needed

Place in `/img/`:
- `hero_acai_amazon.jpg` — Amazon rainforest / açaí harvesting
- `before_after_1.jpg`, `before_after_2.jpg` — testimonial before/after
- `before_1.jpg`, `after_1.jpg` — checkout split
- `product_jar.jpg` — Crave-Off bottle

Product source: Amazon ASIN B0FX1G9L7H — https://www.amazon.com/dp/B0FX1G9L7H
