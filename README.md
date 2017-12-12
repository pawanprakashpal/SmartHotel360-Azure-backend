# SmartHotel360 - Backend Services

Welcome to the SmartHotel360 Backend repository. Here you'll find everything you need to run the backend services locally and/or deploy them in a Azure environment.

## Getting Started

SmartHotel360 uses a **microservice oriented** architecture implemented using Docker containers. There are various services developed in different technologies: .NET Core 2, Java, and Node.js. These services use different data stores like PostgreSQL and SQL Server.

In production all these microservices run in a Kubernetes cluster, powered by Azure Container Service (ACS or AKS).

## Prerequisites

All of the back-end systems run inside of Docker containers. To build locally and see how things work the only requirement is that you install install [Docker](https://www.docker.com/). 

During the installation phase you will notice errors if you haven't set your Docker configuration to use 4 GB of memory. Changing this is simple within the Docker configuration dialog. Just set the memory higher and restart Docker. 

![Docker settings](docs/docker-settings.png)

## Building locally

Clone this repository using your favorite Git client or by using the command: 

`git clone https://github.com/Microsoft/SmartHotel360-Azure-backend.git`

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

## Running microservices locally

All microservices can be run locally using [Docker Compose](https://docs.docker.com/compose/). Starting all of the microservice images is a simple 3-step process. 

### 1. Start the data stores

PostgreSQL and SQL Server databases are stored in Docker containers. These containers should be started first so the databases are on-line when the application logic containers start up. Start the data stores first by typing: 

```
docker-compose up sql-data reviews-data tasks-data
``` 

Wait for those containers to be initialized; you'll know they're ready once the console output stops appearing for longer than a minute. The screen shot below demonstrates the data store containiners' setup being complete and with them in a ready state. 

![Data containers up](docs/data-finished.png)

### 2. Start the microservices

Once the data stores are running, the microservices can be started. Open a new terminal window and execute a second call to docker-compose, this time with no images specified. 

> Note: It is important that you open a **new** terminal window and leave the first one running. Killing the terminal process with a `Ctrl-C` will stop all of the data containers.

```
docker-compose up
``` 
This will start all the remaining containers. Once the containers are online the terminal should stop updating for a few seconds. The terminal screen shot below demonstrates what the terminal should look like once all the microservice containers are running. 

![Microservices up](docs/microservices-up.png)

### 3. Verify services are running

Once the containers are started using the `docker-compose up` commands, their running state can be verified by executing this command:

```
docker ps
```

The terminal window will show all of the containers running. Take note of the ports that have been set for each of the microservice containers. 

![Container ports](docs/containers-and-ports.png)

Each of these ports redirects to port 80 within the container image. Most of these microservices expose an [Open API Specification](https://www.openapis.org/) (formerly known as Swagger) endpoint that describes the back-end REST APIs. To verify the APIs are up and running, use any of the ports in this list to browse the API description page for each of the microservices. 

> Note: not all of these URLs will result with a Swagger-UI test page, but they all should resolve once the microservices are all running. 

|Microservice or API|URL|
|---|---|
|Notifications|[http://localhost:6105](http://localhost:6105)|
|Discounts|[http://localhost:6107](http://localhost:6107)|
|Configuration|[http://localhost:6103](http://localhost:6103)|
|Reviews|[http://localhost:6106](http://localhost:6106)|
|Tasks|[http://localhost:6104](http://localhost:6104)|
|Bookings|[http://localhost:6100](http://localhost:6100)|
|Hotels|[http://localhost:6101](http://localhost:6101)|
|Profiles|[http://localhost:6108](http://localhost:6108)|
|Suggestions|[http://localhost:6102](http://localhost:6102)|
## More info

* [Architecture of SmartHotel360](./docs/architecture.md)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
