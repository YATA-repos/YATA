# Structured Logging Fields Standard

Status: Accepted — aligns with the 2025-10-05 standardization plan.

## Purpose
- Provide a canonical set of structured fields that appear on every high-value log event.
- Improve searchability across Kibana / Supabase log viewers.
- Offer clear guidance for new code paths and reviews ("standard fields included?").

## Naming Rules
- Use `snake_case` for every key (match JSON/SQL expectations).
- Keys map to lower-case ASCII strings; values follow the types below.
- Arrays are allowed but should remain shallow (max depth 2 due to masking policy).

## Field Catalog

| Key | Type | Required | Description | Example |
| --- | --- | --- | --- | --- |
| `operation` | `string` | Required | Stable identifier for the business action.<br>Format: `<domain>.<action>` (e.g. `inventory.consume_materials`). | `order.checkout`
| `stage` | `string` | Optional | Lifecycle stage for the operation. Recommended values: `started`, `succeeded`, `failed`, `cancelled`. | `started`
| `request_id` | `string` | Optional | Correlates to inbound API / UI request. Populate when the log happens inside a tracked request scope. | `req_01H9X7V6J3`
| `flow_id` | `string` | Optional | Long-running business flow identifier (multi-step process, background job, etc.). | `flow_supabase_sync_20251005`
| `actor.user_id` | `string` | Optional | Authenticated user (owner of the action). Hash/tokenized if PII policy requires. | `user_7da42`
| `actor.role` | `string` | Optional | Primary role or permission bucket of the actor (e.g. `manager`, `staff`). | `manager`
| `actor.session_id` | `string` | Optional | Frontend/session token identifier. Use when session-scoped debugging is needed. | `sess_ff129482`
| `store_id` | `string` | Optional | Store/location identifier for multi-location businesses. Leave empty for single-tenant usage. | `store_tokyo_midtown`
| `tenant_id` | `string` | Optional | Tenant/organization identifier (distinct from `actor.user_id`). | `tenant_yata_demo`
| `resource.type` | `string` | Optional | Domain resource touched by the log (`order`, `menu_item`, `material`, etc.). | `order`
| `resource.id` | `string` | Optional | Identifier of the resource (UUID, slug). | `ord_01897f`
| `resource.name` | `string` | Optional | Human readable label (avoid PII; fallback to SKU/name-safe alias). | `Lunch Set A`
| `result.status` | `string` | Optional (required on completion logs) | Operational status outcome. Recommended values: `success`, `failure`, `partial`, `noop`. | `success`
| `result.reason` | `string` | Optional | Detail for failures/cancellations (e.g. validation errors). | `stock_insufficient`
| `result.duration_ms` | `int` | Optional | Elapsed milliseconds for the operation or step. | `482`
| `result.error_code` | `string` | Optional | Domain-specific error code or HTTP status. | `ORD-409`
| `correlation_ids` | `object<string,string>` | Optional | External system IDs keyed by short labels. | `{ "supabase_job": "job-9c2" }`
| `metadata` | `object` | Optional | Free-form extras that follow naming rules. Prefer to keep nested depth ≤ 2. | `{ "items": 4, "retry": false }`

### Required Combinations
- **Start events**: `operation`, `stage=started`, relevant context (actor/request/flow).
- **Success events**: `operation`, `stage=succeeded`, `result.status=success`, include `duration_ms` when measurable.
- **Failure events**: `operation`, `stage=failed`, `result.status=failure`, include `result.reason` and `result.error_code`.

## Builder Usage (preferred)
Use `LogFieldsBuilder` to assemble the standard map and merge domain-specific metadata:

```dart
final fields = LogFieldsBuilder.operation("inventory.consume_materials")
  .withFlow(flowId: flowId, requestId: requestId)
  .withActor(userId: userId, role: currentRole)
  .withStore(storeId: storeId)
  .withResource(type: "order", id: orderId)
  .started()
  .addMetadata({
    "items": consumedItems.length,
    "materials": consumedItems.map((e) => e.materialId).toList(),
  })
  .build();

i("Material consumption started", fields: fields, tag: loggerComponent);
```

Builder methods automatically skip null/empty values and ensure keys follow this standard. When migrating existing logs, prefer the builder over manual map construction.

## Field Quality Checklist
- [ ] All keys are in `snake_case` (nested objects included).
- [ ] Sensitive identifiers go through masking (`pii_masking_enabled`) or arrive pre-hashed.
- [ ] `operation` value is stable and documented (avoid ad-hoc wording per log line).
- [ ] `stage` + `result.status` combination reflects the lifecycle correctly.
- [ ] Free-form metadata stays shallow (< 3 levels) and uses descriptive keys.

## Examples

### Order Checkout Success
```json
{
  "lvl": "info",
  "tag": "OrderManagementService",
  "msg": "Checkout completed",
  "fields": {
    "operation": "order.checkout",
    "stage": "succeeded",
    "request_id": "req_02QA",
    "actor": {"user_id": "user_123"},
    "resource": {"type": "order", "id": "ord_901"},
    "result": {"status": "success", "duration_ms": 482},
    "metadata": {"items": 3, "payment_method": "card"}
  }
}
```

### Inventory Consumption Failure
```json
{
  "lvl": "warn",
  "tag": "OrderStockService",
  "msg": "Stock validation rejected",
  "fields": {
    "operation": "inventory.consume_materials",
    "stage": "failed",
    "flow_id": "flow_checkout_20251005_T01",
    "actor": {"user_id": "user_123", "role": "staff"},
    "resource": {"type": "menu_item", "id": "menu_88"},
    "result": {
      "status": "failure",
      "reason": "stock_insufficient",
      "error_code": "INV-OUT-001"
    },
    "metadata": {
      "requested_quantity": 2,
      "available_quantity": 0
    }
  }
}
```

## Change Management
- Treat this document as the single source of truth for structured keys.
- New keys require PR discussion and update to this doc.
- Code reviews should verify `LogFieldsBuilder` (or equivalent) is used when introducing new high-level logs.
