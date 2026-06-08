# Config templates — root + packages/config

> Apply `{{PROJECT_NAME}}` and `{{SCOPE}}` substitutions. These are faithful,
> simplified versions of the reference monorepo's configuration.

## `package.json` (root)

```json
{
  "name": "{{PROJECT_NAME}}",
  "private": true,
  "packageManager": "pnpm@9.15.0",
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "typecheck": "turbo typecheck",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,md,yaml,yml}\" --ignore-path .gitignore",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,md,yaml,yml}\" --ignore-path .gitignore",
    "test": "turbo test",
    "db:gen-types": "supabase gen types typescript --linked > packages/db/src/types.ts"
  },
  "devDependencies": {
    "@eslint/js": "^9.18.0",
    "eslint": "^9.18.0",
    "prettier": "^3.4.2",
    "tsx": "^4.19.0",
    "turbo": "^2.3.3",
    "typescript": "^5.7.3",
    "typescript-eslint": "^8.20.0",
    "vitest": "^4.0.0"
  }
}
```

## `pnpm-workspace.yaml`

```yaml
packages:
  - 'apps/*'
  - 'apps/agents/*'
  - 'packages/*'
```

## `turbo.json`

```json
{
  "$schema": "https://turbo.build/schema.json",
  "ui": "tui",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "dev": { "cache": false, "persistent": true },
    "lint": { "outputs": [] },
    "typecheck": { "dependsOn": ["^build"], "outputs": [] },
    "test": { "dependsOn": ["^build"], "outputs": ["coverage/**"] }
  }
}
```

## `tsconfig.json` (root)

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": { "strict": true, "skipLibCheck": true }
}
```

## `prettier.config.js`

```js
/** @type {import("prettier").Config} */
module.exports = {
  semi: false,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'es5',
  printWidth: 100,
}
```

## `eslint.config.mjs`

```js
import js from '@eslint/js'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  { ignores: ['**/dist/**', '**/.next/**', '**/node_modules/**'] },
  js.configs.recommended,
  ...tseslint.configs.recommended
)
```

## `.gitignore`

```
node_modules/
dist/
.next/
.turbo/
coverage/
*.log
.env
.env.local
.DS_Store
```

## `.env.example` (root — documents every env var the slice uses)

```bash
# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=

# API
PORT=4000
CORS_ORIGINS=http://localhost:3000

# Web → API
NEXT_PUBLIC_API_URL=http://localhost:4000

# MCP server
MCP_API_KEY=dev-secret
```

## `packages/config/package.json`

```json
{
  "name": "{{SCOPE}}/config",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "exports": {
    "./typescript/base": "./typescript/base.json",
    "./typescript/node": "./typescript/node.json",
    "./typescript/nextjs": "./typescript/nextjs.json"
  }
}
```

## `packages/config/typescript/base.json`

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "allowImportingTsExtensions": true,
    "noEmit": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "isolatedModules": true,
    "skipLibCheck": true
  }
}
```

## `packages/config/typescript/node.json`

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "./base.json",
  "compilerOptions": {
    "lib": ["ES2022"],
    "types": ["node"],
    "noEmit": false,
    "outDir": "dist",
    "declaration": true
  },
  "exclude": ["node_modules", "dist"]
}
```

## `packages/config/typescript/nextjs.json`

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "./base.json",
  "compilerOptions": {
    "plugins": [{ "name": "next" }],
    "jsx": "preserve",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "allowJs": true,
    "incremental": true
  },
  "exclude": ["node_modules"]
}
```
