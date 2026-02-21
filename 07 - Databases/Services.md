---
tags: [databases]
---

# Services

Concepts for cloud service and infrastructure models.

## IaaS — Infrastructure as a Service

Online services providing high-level APIs over physical compute resources. A hypervisor (Xen, KVM, VMware, Hyper-V) runs virtual machines as guests, and pools of hypervisors support scaling up and down on demand.

- [IaaS — Wikipedia](https://en.wikipedia.org/wiki/Infrastructure_as_a_service)

## IaC — Infrastructure as Code

Managing data centers through machine-readable definition files rather than manual configuration. Supports both scripted and declarative approaches; declarative is preferred.

IaC supports IaaS but is distinct from it — IaC is the *how*, IaaS is the *what*.

- [IaC — Wikipedia](https://en.wikipedia.org/wiki/Infrastructure_as_code)
- See also: [[Terraform]], [[Pipelines]]
