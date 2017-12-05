# SmartHotel360 - Backend Services

Welcome to the SmartHotel360 Backend repository. Here you'll find everything you need to run the backend services locally and/or deploy them in a Azure environment.

# Getting Started

Smarthotel360 uses a **microservice oriented** architecture implemented using Docker containers. There are various services developed in different technologies: netcore2, java and nodejs. These services use different data stores like Postgres and SQL Server.

In production all these microservices run in a Kubernetes cluster, powered by Azure Container Service (ACS or AKS).

# Building all microservices locally

For building all microservices **there is no need to have any SDK installed**. You don't need to have netcore2 SDK, nor nodejs nor JDK8. Just Docker.

Go to `/src` folder and type:

```
docker-compose build
```

After some minutes you'll have all Docker images created on your computer. Following images will be created (type `docker images` to see all images you have in your system):

* `smarthotels/suggestions`
* `smarthotels/notifications`
* `smarthotels/reviews`
* `smarthotels/hotels`
* `smarthotels/tasks`
* `smarthotels/discounts`
* `smarthotels/profiles`
* `smarthotels/configuration`

# Running microservices locally

To run all microservices locally (assuming you have Docker images created), just go to to `/src` folder and type `docker-compose up`. This will start all services and data stores (sql server, postgres).

> However it is recommended to start first the data stores by typing `docker-compose up sql-data reviews-data tasks-data` and wait for those containers to be initialized (just wait until no more log messages appear on console). Then type `docker-compose up` to start the remaining containers.

# More info

* [Architecture of SmartHotel360](./docs/architecture.md)

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
