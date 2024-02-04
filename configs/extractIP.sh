#!/bin/bash

sudo kubectl get po -o custom-columns="NODE-NAME":.spec.nodeName,"POD-ID":.status.podIP --no-headers
