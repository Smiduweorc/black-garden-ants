import assert from "node:assert/strict";
import { test } from "node:test";

// NodeNext resolution: import the .js specifier. Bun maps it to the .ts source
// itself; under Node, tsx does.
import { greet } from "../src/index.js";

test("greet", () => {
	assert.equal(greet("world"), "hello, world");
});
