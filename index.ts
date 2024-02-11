import { Application } from "https://deno.land/x/oak/mod.ts";
import { parse } from "./deps.ts";
import { greet } from "./lib.ts";

const args = parse(Deno.args);
const name = args.name || "World";
const app = new Application();

app.use((ctx) => {
  ctx.response.body = name;
});

await app.listen({ port: 8000 });
console.log(greet(name));
