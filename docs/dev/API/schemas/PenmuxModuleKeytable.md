# Penmux Module Keytable Schema

The penmux module keytalbe xsd schema is the definition of keymappings to use specific module functions.

## 1. The Schema

Here is the whole schema for the current version:

```
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:complexType name="KeyType">
    <xs:sequence>
      <xs:element name="Key" type="xs:string" />
      <xs:element name="Func" type="xs:string" />
      <xs:element name="Description" type="xs:string" />
    </xs:sequence>
  </xs:complexType>

  <xs:element name="PenmuxModuleKeytable">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="PrefixKey" type="xs:string" />
        <xs:element name="Key" type="KeyType" minOccurs="1" maxOccurs="unbounded" />
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

## 2. Detailed Explanation

We'll go through all the relevant parts of the schema and describe what the elements are for.

### 2.1 PenmuxModuleKeytable

The PenmuxModuleKeytable is the actual module keytable description itself:
```
<xs:element name="PenmuxModuleKeytable">
  <xs:complexType>
    <xs:sequence>
      <xs:element name="PrefixKey" type="xs:string" />
      <xs:element name="Key" type="KeyType" minOccurs="1" maxOccurs="unbounded" />
    </xs:sequence>
  </xs:complexType>
</xs:element>
```

We'll now go through all the elements one by one to describe what they are doing.

#### PrefixKey

The PrefixKey defines the key that is needed to enter the module keytable. All other keybindings require this prefix to be executed.

#### Key

The Key element is of type [KeyType](#keytype) and defines the function triggered by the key press.

### <a name="keytype"></a>2.2 KeyType

A KeyType defines a fuction that is requested to be executed by the module:
```
<xs:complexType name="KeyType">
  <xs:sequence>
    <xs:element name="Key" type="xs:string" />
    <xs:element name="Func" type="xs:string" />
    <xs:element name="Description" type="xs:string" />
  </xs:sequence>
</xs:complexType>
```

We'll now go through the different types and the attributes and describe their behavior.

#### Name

The key which is referenced. A.e.: 'n' will refer to the n key of the keyboard.

#### Func

The Func element is a string that will be parsed by the module and matched to a function that should be executed.

More about this in the [Module development guide](**TODO**)

#### Description

The Description element is a description of what the function is about to do.
