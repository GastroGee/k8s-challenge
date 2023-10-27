# Nomad Deployment 
This is a personal attempt to solve the same problem using Hashicorp container orchestration program called NOMAD 

Nomad could also serve as a kubernetes alternative which runs as a single binary with a small resource footprint and supports a wide range of workloads beyond containers, including Windows, Java, VM, Docker, and more.

In Nomad, the general hierachy for a job is:
```
job
  \_ group
  |     \_ task
  |     \_ task
  |
  \_ group
        \_ task
        \_ task
```

## Persistent Volumes in Nomad?
Nomad does what nomad does best; container orchestration. Every other bit of neccesary to a stateful applications need to be handle by external providers. 
e.g service discovery and registration can be handled by consul; secrets management can be handled by vault; volume management can be handled by a CSI or Portworx. 

