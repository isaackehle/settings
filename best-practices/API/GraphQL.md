---
tags: [development, api]
---

# GraphQL

A query language for APIs that allows clients to request exactly the data they need.

## Key Features

- **Single Endpoint** — One URL for all operations
- **Typed Schema** — Strongly typed API contracts
- **Introspective** — API can describe its own schema
- **Real-time** — Subscriptions for live data

## Operations

- **Query** — Read data
- **Mutation** — Modify data
- **Subscription** — Real-time updates

## Example Query

```graphql
query {
  user(id: "123") {
    name
    email
    posts {
      title
      content
    }
  }
}
```

## References

- [GraphQL Documentation](https://graphql.org/)

