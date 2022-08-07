FROM node:16-bullseye-slim as base
ENV NODE_ENV production
RUN apt-get update

FROM base as deps
WORKDIR /myapp
ADD package.json package-lock.json .npmrc ./
RUN npm install --production=false

FROM base as production-deps
WORKDIR /myapp
COPY --from=deps /myapp/node_modules /myapp/node_modules
ADD package.json package-lock.json .npmrc ./
RUN npm prune --production

FROM base as build
WORKDIR /myapp
COPY --from=deps /myapp/node_modules /myapp/node_modules
ADD . .
RUN npm run build

FROM base
ENV PORT="8080"
ENV NODE_ENV="production"
WORKDIR /myapp
COPY --from=production-deps /myapp/node_modules /myapp/node_modules
COPY --from=build /myapp/build /myapp/build
COPY --from=build /myapp/public /myapp/public
COPY --from=build /myapp/package.json /myapp/package.json
COPY --from=build /myapp/start.sh /myapp/start.sh
ENTRYPOINT [ "./start.sh" ]
