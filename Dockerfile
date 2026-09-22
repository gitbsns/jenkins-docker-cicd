# ---- Base image ----
# Alpine version chhoti aur lightweight hoti hai (~50MB vs ~900MB full node image)
# Production images hamesha slim rakhni chahiye - security aur speed dono ke liye.
FROM node:20-alpine

# Container ke andar working directory set kar rahe hain.
# Iske baad ke saare commands isi folder ke andar chalenge.
WORKDIR /usr/src/app

# ---- Build metadata ----
# Yeh values build time par --build-arg se pass hongi (CI/CD ya manual build).
# Isse har image ka exact build number, git commit, aur build date pata chal sakega -
# "latest" tag ke andar bhi pata chalega ki actually kaunsa build chal raha hai.
ARG BUILD_NUMBER=unknown
ARG GIT_SHA=unknown
ARG BUILD_DATE=unknown

# Labels: bina container ke andar jaaye bhi "docker inspect" se dikh jayenge
LABEL build.number=$BUILD_NUMBER
LABEL build.git_sha=$GIT_SHA
LABEL build.date=$BUILD_DATE

# Runtime par bhi available rahe, isliye ENV bhi set kar rahe hain
ENV BUILD_NUMBER=$BUILD_NUMBER

# File mein likh rahe hain taaki container ke andar `cat /BUILD_NUMBER` se check ho sake
RUN echo "BUILD_NUMBER=$BUILD_NUMBER" > /BUILD_NUMBER && \
    echo "GIT_SHA=$GIT_SHA" >> /BUILD_NUMBER && \
    echo "BUILD_DATE=$BUILD_DATE" >> /BUILD_NUMBER

# Sirf package.json pehle copy karo (poora code nahi).
# Wajah: Docker layer caching. Agar sirf app.js change hua ho aur
# package.json same ho, to "npm install" wala layer dobara nahi chalega -
# build fast ho jata hai. Yehi real-world Docker optimization hai.
COPY package*.json ./

RUN npm install --production

# Ab baaki app code copy karo
COPY . .

# Container ye port expose karega (documentation ke liye, actual mapping
# "docker run -p" ya Kubernetes Service mein hoti hai)
EXPOSE 3000

# Container start hone par ye command chalegi
CMD ["node", "app.js"]
