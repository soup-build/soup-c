import "Soup|Build.Utils:./list-extensions" for ListExtensions

class Assert {
	static True(value) {
		if (!value) {
			Fiber.abort("Value must be true")
		}
	}

	static False(value) {
		if (value) {
			Fiber.abort("Value must be false")
		}
	}

	static ListEqual(expected, actual) {
		if (!ListExtensions.SequenceEqual(expected, actual)) {
			System.print("Expected: %(expected)")
			System.print("Actual  : %(actual)")
			Fiber.abort("Values must be equal")
		}
	}

	static Equal(expected, actual) {
		if (!(expected == actual)) {
			System.print("Expected: %(expected)")
			System.print("Actual  : %(actual)")
			Fiber.abort("Values must be equal")
		}
	}
}