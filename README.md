# Wain App

Flutter application for place discovery, offers, and merchant participation.

## Getting Started

```bash
flutter pub get
flutter run
```

## Plan Review Framework (Implemented)

The repository includes a standard framework to review and improve growth-oriented plans.

- Framework guide: `docs/plan_review/README.md`
- Plan input template: `docs/plan_review/templates/plan_input_v1.template.json`
- Review output template: `docs/plan_review/templates/review_output_v1.template.json`
- Review generator script: `scripts/plan_review_scaffold.js`

### Generate A Review Scaffold

```bash
node scripts/plan_review_scaffold.js --input docs/plan_review/templates/plan_input_v1.template.json --output docs/plan_review/reviews/example_review.md
```

### JSON Output (Optional)

```bash
node scripts/plan_review_scaffold.js --input <plan.json> --format json
```

## Release Checklists

- Merchant dashboard delta release checklist:
  - `docs/release/merchant_dashboard_release_checklist.md`
