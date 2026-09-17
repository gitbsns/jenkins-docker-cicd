# ---- Base image ----
# Alpine version chhoti aur lightweight hoti hai (~50MB vs ~900MB full node image)
# Production images hamesha slim rakhni chahiye - security aur speed dono ke liye.
FROM node:20-alpine

# Container ke andar working directory set kar rahe hain.
# Iske baad ke saare commands isi folder ke andar chalenge.
WORKDIR /usr/src/app

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
