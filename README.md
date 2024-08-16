# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version
3.3.4

* Configuration

Required Settings records

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

cap production deploy

* Design Patterns

All modules are namespaced

ex. Sales::Invoice, Inventory::Product

* Roles and Abilities

we use RBAC: https://medium.com/@solidity101/%EF%B8%8F-demystifying-role-based-access-control-rbac-pattern-a-comprehensive-guide-bd18b144fc81

users and roles have a many to many relationship
all permissions and ACLs are defined in the Ability class

* Deployment

First you should prepare an EC2 server to be able to receive / run the project
Requirements:

Ruby 3.3.4 systemwide with jemalloc and YJIT turned on: --with-jemalloc --enable-yjit

https://github.com/ruby/ruby/blob/master/doc/yjit/yjit.md#installation

apt-get install --no-install-recommends -y libjemalloc2
ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true,stats_print:true" \
    RUBY_YJIT_ENABLE="1"

bundle / bundler should be installed systemwide
run bundle





