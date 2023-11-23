# Penmux Module Schema

The penmux module xsd schema is the definition of what a module is made of. It contains stuff like Name of the module, options, etc.

## 1. The Schema

Here is the whole schema for the current version:
```
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:complexType name="OptionType">
    <xs:sequence>
      <xs:element name="Name" type="xs:string" />
      <xs:element name="Description" type="xs:string" />
    </xs:sequence>
    <xs:attribute name="Mandatory"
    type="xs:boolean"
    use="optional" />
    <xs:attribute name="Private"
    type="xs:boolean"
    use="optional" />
    <xs:attribute name="Exported"
    type="xs:boolean"
    use="optional" />
    <xs:attribute name="Provided"
    type="xs:boolean"
    use="optional" />
    <xs:attribute name="Volatile"
    type="xs:boolean"
    use="optional" />
  </xs:complexType>
  <xs:complexType name="OptionTypeString">
    <xs:complexContent>
      <xs:restriction base="OptionType">
        <xs:sequence>
          <xs:element name="Name" type="xs:string" />
          <xs:element name="Description" type="xs:string" />
        </xs:sequence>
        <xs:attribute name="Mandatory"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Private"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Exported"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Provided"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Volatile"
        type="xs:boolean"
        use="optional" />
      </xs:restriction>
    </xs:complexContent>
  </xs:complexType>
  <xs:complexType name="OptionTypeBool">
    <xs:complexContent>
      <xs:restriction base="OptionType">
        <xs:sequence>
          <xs:element name="Name" type="xs:string" />
          <xs:element name="Description" type="xs:string" />
        </xs:sequence>
        <xs:attribute name="Mandatory"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Private"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Exported"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Provided"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Volatile"
        type="xs:boolean"
        use="optional" />
      </xs:restriction>
    </xs:complexContent>
  </xs:complexType>
  <xs:complexType name="OptionTypeInt">
    <xs:complexContent>
      <xs:restriction base="OptionType">
        <xs:sequence>
          <xs:element name="Name" type="xs:string" />
          <xs:element name="Description" type="xs:string" />
        </xs:sequence>
        <xs:attribute name="Mandatory"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Private"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Exported"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Provided"
        type="xs:boolean"
        use="optional" />
        <xs:attribute name="Volatile"
        type="xs:boolean"
        use="optional" />
      </xs:restriction>
    </xs:complexContent>
  </xs:complexType>

  <xs:complexType name="PenmuxConsumer">
    <xs:sequence>
      <xs:element name="Name" type="xs:string" />
      <xs:element name="Description" type="xs:string" />
    </xs:sequence>
    <xs:attribute name="NoNotify"
    type="xs:boolean"
    use="optional" />
  </xs:complexType>

  <xs:element name="PenmuxModule">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="Name" type="xs:string" />
        <xs:element name="Description" type="xs:string" />
        <xs:element name="HasRun" type="xs:boolean" minOccurs="0" maxOccurs="1" />
        <xs:element name="CmdPrio" type="xs:int" minOccurs="0" maxOccurs="1" />
        <xs:element name="NotifyOptions" type="xs:boolean" minOccurs="0" maxOccurs="1" />
        <xs:element name="Option" type="OptionType" minOccurs="0" maxOccurs="unbounded" />
        <xs:element name="Consumes" type="PenmuxConsumer" minOccurs="0" maxOccurs="unbounded" />
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

## 2. Detailed Explanation

We'll go through all the relevant parts of the schema and describe what the elements are for and also sometimes, why they were created ;)

### 2.1 PenmuxModule

The PenmuxModule is the actual module description itself:
```
  <xs:element name="PenmuxModule">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="Name" type="xs:string" />
        <xs:element name="Description" type="xs:string" />
        <xs:element name="HasRun" type="xs:boolean" minOccurs="0" maxOccurs="1" />
        <xs:element name="CmdPrio" type="xs:int" minOccurs="0" maxOccurs="1" />
        <xs:element name="NotifyOptions" type="xs:boolean" minOccurs="0" maxOccurs="1" />
        <xs:element name="Option" type="OptionType" minOccurs="0" maxOccurs="unbounded" />
        <xs:element name="Consumes" type="PenmuxConsumer" minOccurs="0" maxOccurs="unbounded" />
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

We'll now go through all the elements one by one to describe what they are doing.

#### Name

The name is just the module name. It is important to know, that this name has to be unique over all modules (at the moment there is no check or anything implemented to avoid errors) and it is case sensitive.
That means that (described in [Module development guide](**TODO**)) it must match the module folders, options.xml, keytable.xml and so on including case to work correctly.

#### Description

The description is the modules description. Yes simple as that just describe what the module is doing in a way that a user has the possibility to understand if he wants to use it or not ^^

#### HasRun

This boolean flag tells the API if a module has a run functionality implemented. It is existing to show a user only matching modules (including a run functionality) as selection when issuing a run command.

This element is optional and should only be added with a value "true", if the module has a run functionality.
If it is left away, it is interpreted as false.

#### CmdPrio

This element is used to order the execution of an optional default function that is called during creation of a new pane, window, etc.

There is a longer story behind this element and it is needed in (at least as far as I was thinking till now) in rare cases, but can be very handy.

We will get deeper into this in the [Module development guide](**TODO**) but for now the following should be fine:

This flag is an integer that defines the priority of the function. Higher values means less prior and will lead to execute the function after functions from other modules with lower values.

If a module (which should be the case for the vast majority) does not use a default function this element should be left out.

#### NotifyOptions

This element is telling the API that a module wants to get notified for any change of options from any module.

Like CmdPrio the use case for this is rare (like for the [Session](docs/modules/auxilliary/Session.md) module) but still existing.

If a module has this element set to 'true' the API will call the corresponding function (more info at [Module development guide](**TODO**)) of the module on every option change.

A limitation for notifications is that private options that are not set (via attribute) as exported won't trigger any notifications.

In most cases this element should be left out as for the main purpose of receiving messages about options [Consumes](#Consumes) should be used.

#### Option

Option elements are optional and can occur multiple times. They are telling what options a module has and what flags (attributes) they have.

For more information about the attributes, etc. refer to the [OptionType](#OptionType).

#### <a name="#Consumes"></a>Consumes

This element is a [PenmuxConsumer](#PenmuxConsumer) and optional. It can be added multiple times, if the module is consuming multiple options from other modules.

The purpose of this element is to let a module use provided options from other modules to benefit from them.

As an example the [ScriptLog module](docs/modules/reporting/ScriptLog.md) consumes the 'SessionDir' from the [Session module](docs/modules/auxilliary/Session.md) to log into the session directory when working inside of a session.

Note that only [Options](#OptionType) marked as 'Provided' are possible to consume.

For detailed information about this refer to the [PenmuxConsumer](#PenmuxConsumer).
