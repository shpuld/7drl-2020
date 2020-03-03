#define printf(x, ...) print(sprintf(x, __VA_ARGS__))

string current_test;
int test_passes;
int test_fails;

void(string funcname) begin_test =
{
	current_test = funcname;
	test_passes = 0;
	test_fails = 0;
}

void() end_test =
{
	// ^2 = green, ^1 = red
	int color = test_fails == 0 ? 2 : 1;
	printf("^%i%s done, passed tests: %i/%i\n", color, current_test, test_passes, test_passes + test_fails);
}

void(float actual, float expected) float_expect =
{
	if (actual != expected)
	{
		printf("^1- %s failure: expected: %f, actual: %f\n", current_test, expected, actual);
		test_fails += 1;
	}
	else
	{
		test_passes += 1;
	}
};

void(vector actual, vector expected) vector_expect =
{
	if (actual != expected)
	{
		printf("- %s failure: expected: %v, actual: %v\n", current_test, expected, actual);
		test_fails += 1;
	}
	else
	{
		test_passes += 1;
	}
};

void(string actual, string expected) string_expect =
{
	if (actual != expected)
	{
		printf("- %s failure: expected: %s, actual: %s\n", current_test, expected, actual);
		test_fails += 1;
	}
	else
	{
		test_passes += 1;
	}
};

void(float actual) expect_true =
{
	if (!actual)
	{
		printf("- %s failure: expected: TRUE, actual: FALSE\n", current_test);
		test_fails += 1;
	}
	else
	{
		test_passes += 1;
	}
};

void(float actual) expect_false =
{
	if (actual)
	{
		printf("- %s failure: expected: FALSE, actual: TRUE\n", current_test);
		test_fails += 1;
	}
	else
	{
		test_passes += 1;
	}
};
