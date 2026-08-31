import assert from "node:assert/strict";
import { test } from "node:test";

// NodeNext resolution: import the .js specifier; tsx maps it to the .ts source.
import { greet } from "../src/index.js";

test("greet", () => {
	assert.equal(greet("world"), "hello, world");
});
