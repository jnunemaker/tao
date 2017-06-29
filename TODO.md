* use timestamp instead of datetime?
* memcached wrapping, read through, write through, both?
* should count be limited to 6000 and somehow denote that there are more?
* get tests for:
  * does not include ids from other id1's
  * does not include ids from other types
  * does not include ids not included in id2 set
* assocation add/create
  * should add or overwrite but only add's
* check semantics in general based on paper (e.g. are associations always sorted descending by time?)
* migration generator
* more convenience methods on object/association for working together
* enforced schema for key/value on objects (and associations?)
* allow encode/decode with something other than json
* batch methods for objects (get_multi, etc.)
