FROM flant/shell-operator:v1.0.4

RUN apk --no-cache add curl

RUN curl -L --http1.1 https://cnfl.io/ccloud-cli | sh -s -- -b /usr/bin latest

RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl -O /bin/kubectl && chmod +x /bin/kubectl

ADD hooks /hooks
