#!/bin/bash

exit_code=0

echo "Run go tool vet -all"
for file in $(find . -type f -name '*.go' -not -path "./vendor/*"); do
    go tool vet -all $file 2>&1 | tee fail ; test -z "$(cat fail)"; reply=$?
    rm fail

    if [ "$reply" -ne "0" ]
    then
        exit_code=$reply
    fi
done

echo "Run go lint"
go get -u github.com/golang/lint/golint

# check each directory (subpackage and main) without vendor
for dir in $(go list ./... | grep -v vendor); do
    golint -set_exit_status=1 "${GOPATH}/src/$dir/"; reply=$?
    
    if [ "$reply" -ne "0" ]
    then
        exit_code=$reply
    fi
done

echo "Run gofmt"
gofmt -d $(find . -type f -name '*.go' -not -path "./vendor/*") | tee fail ; test -z "$(cat fail)"; reply=$?
rm fail

if [ "$reply" -ne "0" ]
then
    exit_code=$reply
fi

echo "Run error checking"
go get -u github.com/kisielk/errcheck

for dir in $(go list ./... | grep -v vendor); do
    errcheck "$dir"; reply=$?;
    
    if [ "$reply" -ne "0" ]
    then
        exit_code=$reply
    fi
done

echo "Run tests"
for dir in $(go list ./... | grep -v vendor); do
    go test -v "$dir/"; reply=$?
    
    if [ "$reply" -ne "0" ]
    then
        exit_code=$reply
    fi
done

exit "$exit_code"
