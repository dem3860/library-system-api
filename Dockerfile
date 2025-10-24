# ===== Builder Stage =====
# Build the application
FROM node:20-bullseye AS builder
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy dependency definition files
COPY package.json pnpm-lock.yaml ./

# Install all dependencies (including devDependencies needed for build)
RUN pnpm install --frozen-lockfile

# Copy the rest of the application code
COPY . ./

# Build the application (TypeScript to JavaScript)
RUN pnpm run build

# ===== Runner Stage =====
# Create the final, minimal image
FROM node:20-bullseye AS runner
WORKDIR /app

# Install pnpm globally again for the runner stage
RUN npm install -g pnpm

# Create non-root user and group
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 hono

# Copy necessary files from the builder stage
COPY --from=builder --chown=hono:nodejs /app/dist ./dist
COPY --from=builder --chown=hono:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=hono:nodejs /app/package.json ./package.json
COPY --from=builder --chown=hono:nodejs /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder --chown=hono:nodejs /app/prisma ./prisma
# Switch to the non-root user
USER hono

# Expose the application port
EXPOSE 8787

# Define the command to run the application
CMD ["node", "/app/dist/src/index.js"]
