# Semantic Layer

A project member browses the published semantic layer by source, opens an explore, and inspects its fields and their descriptions. Sources and fields have their own URLs.

## Sub-features

- `layer-sources` lists the project's sources and groups their explores.
- `layer-explore` opens an explore's Fields tab.
- `layer-field` opens a field's details from the list.

## How to get to it (user POV)

- `Browse` → `Semantic Layer`, or `$ENV_URL/projects/$P/semantic-layer`.

## Driving it

Preconditions:

- Sign in as a user who can view the project. The preview's Jaffle shop seed has a PostgreSQL source with an `Orders` explore.

- **Browse.** Select `PostgreSQL` in the `Semantic Layer` tree, then `Orders`. The `Fields` tab lists dimensions and their descriptions.
- **Inspect a field.** Select `Status`. The detail dialog names the field as a string dimension. The URL ends in `/semantic-layer/explores/orders/fields/orders_status`.

## Gotchas

- The seed's dbt connection is read-only: a note above the tree reads `Read-only. This dbt connection can't be written to.`, and the published field list is still available.
