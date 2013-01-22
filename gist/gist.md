# Gist service

Endpoint: https://api.github.com

# List user gists

Lists a user's gists

## Request:

````
GET /users/{user}/gists
````

# List my gists

## Request:

````
GET /gists
````

# List public gists

## Request:

````
GET /gists/public
````

# List starred gists

## Request:

````
GET /gists/starred
````

# Get single gist

Obtains a single gist by id

## Request:

````
GET /gists/{id}
````

# Create gist

## Request:

````
POST /gists
````

# Edit gist

## Request:

````
POST /gists/{id}
````

# Star gist

## Request:

````
POST /gists/{id}/star
````

# Unstar gist

## Request:

````
DELETE /gists/{id}/star
````

# Check gist starred

## Request:

````
GET /gists/{id}/star
````

# Fork gist

## Request:

````
POST /gists/{id}/forks
````

# Delete gist

## Request:

````
DELETE /gists/{id}
````