---
tags: [development, api]
---

# SOAP

Simple Object Access Protocol - an XML-based messaging protocol for exchanging structured information.

## Key Features

- **XML-based** — Uses XML for message format
- **WSDL** — Web Services Description Language for service definitions
- **WS-Security** — Built-in security standards
- **Reliable** — Guaranteed message delivery

## Message Structure

```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope/">
  <soap:Header>
    <!-- Header information -->
  </soap:Header>
  <soap:Body>
    <!-- Request/Response data -->
  </soap:Body>
</soap:Envelope>
```

## WSDL Example

```xml
<definitions>
  <message name="getUserRequest">
    <part name="userId" type="xsd:int"/>
  </message>
  <message name="getUserResponse">
    <part name="user" type="tns:User"/>
  </message>
</definitions>
```

## References

- [SOAP Protocol](https://www.w3.org/TR/soap/)
- [WSDL Specification](https://www.w3.org/TR/wsdl/)