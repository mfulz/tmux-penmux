# Penmux Schemas definition

Penmux is using xml files to define the modules, options and keytables. Therefore xsd schemas are shipped with penmux to have a clear definition of what a module must provide and what can be used / interpreted by the penmux API.

## 1. Schemas

In the current version there are three xsd schemas present (they can be located under the schemas folder):

- [penmux-module.xsd](schemas/PenmuxModule.md)
- [penmux-module-options.xsd](schemas/PenmuxModuleOptions.md)
- [penmux-module-keytable.xsd](schemas/PenmuxModuleKeytable.md)

### Penmux Module

The penmux-module.xsd schema defines a module at the base level. This means it describes what features a module is using,
what it provides, and so on.

The corresponding xml file must be implemented for every module.

### Penmux Module Options

The penmux-module-options.xsd schema defines what options a module has. This is meant to define the options that can be
configured by a user and will not include stuff like provides, etc.

The corresponding xml file is optional as a module could theoretically run without any options.

### Penmux Module Keytable

The penmux-module-keytable.xsd schema defines what keybindings a module has. This is basically a lookup that will tell a module
which func is called without having to let the module know anything about the keybindings at all.

The corresponging xml file is optional and only needed if a module has some functions that a user can call directly.

## 2. Disclaimer

Why I decided to use xml, some may ask. Honestly I'm not a big fan of xml (especially for data exchange), because there is
much overhead and mostly much more data in the meta data (tags, etc. pp) than what has to be transferred.

But for a clear definition of what has to be put into a module description it just felt right. By using a xsd schema it will
"force" the modules to have a correct definition without the need of extensive error checking, etc.

That does - especially not in this case - not mean that a xml can't be invalid (at the moment I decided to not validate the xml
as I want to have the possibility to provide a backward compatible API) but by using tools like xmlstarlet and with the actual
design it would just be a missing value, etc. without the need to check for various possible error cases.

This way it will just error out, where essential things are wrong, still work if just optional stuff is wrong, etc.

The drawback here is, that there is no clear error feedback to developers, when something goes wrong because of errors inside
the xml definitions of a module, but this is (at least in my opinion) a more easy task, as a developer should be able
(and a dev SHOULD do such things by intention anyway) to verify the xml files against the schema before using them.

So to make things short: Even if (in my personal opinion) xml is a horrible format for exchanging data over a network it is a really good
format together with a schema to provide such things like an API interface, that's the reason why I decided to use it ;)
