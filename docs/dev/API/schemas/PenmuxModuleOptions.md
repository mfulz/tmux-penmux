# Penmux Module Options Schema

The penmux module options xsd schema is the definition of default values for module options.

## 1. The Schema

Here is the whole schema for the current version:

```
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:complexType name="OptionType">
    <xs:sequence>
      <xs:element name="Name" type="xs:string" />
      <xs:element name="DefaultValue" type="xs:string" />
    </xs:sequence>
  </xs:complexType>

  <xs:element name="PenmuxModuleOptions">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="Option" type="OptionType" minOccurs="1" maxOccurs="unbounded" />
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

## 2. Detailed Explanation

We'll go through all the relevant parts of the schema and describe what the elements are for.

### 2.1 PenmuxModuleOptions

The PenmuxModuleOptions is the actual module options description itself:
```
<xs:element name="PenmuxModuleOptions">
  <xs:complexType>
    <xs:sequence>
      <xs:element name="Option" type="OptionType" minOccurs="1" maxOccurs="unbounded" />
    </xs:sequence>
  </xs:complexType>
</xs:element>
```

We'll now go through all the elements one by one to describe what they are doing.

#### Option

Option elements can occur multiple times. They are telling what default values are set for module options.

For more information refer to the [OptionType](#optiontype).

### <a name="optiontype"></a>2.2 OptionType

An OptionType defines what default value an option has if no value is set by the user in the active session:
```
<xs:complexType name="OptionType">
  <xs:sequence>
    <xs:element name="Name" type="xs:string" />
    <xs:element name="DefaultValue" type="xs:string" />
  </xs:sequence>
</xs:complexType>
```

We'll now go through the different types and the attributes and describe their behavior.

#### Name

The name element references the module option which default value should be defined.

#### DefaultValue

The DefaultValue element holds the value which should be taken as default if no value is set in the session.
