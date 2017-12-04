#!/bin/bash

env="live"

TF_VAR_Environment=${env}
TF_VAR_NetworkName=${env}

export TF_VAR_NetworkName TF_VAR_Environment
