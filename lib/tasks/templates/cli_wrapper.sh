#!/bin/bash

cd ~/.loom/<%= lib_name %>
exec ./<%= lib_name.downcase %> "$@"
