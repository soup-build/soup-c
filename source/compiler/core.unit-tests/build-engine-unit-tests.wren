// <copyright file="build-engine-unit-tests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest
import "mwasplund|Soup.Build.Utils:./path" for Path
import "mwasplund|Soup.Build.Utils:./build-operation" for BuildOperation
import "../../test/assert" for Assert
import "../core/build-engine" for BuildEngine
import "../core/mock-compiler" for MockCompiler
import "../core/build-arguments" for BuildArguments, BuildOptimizationLevel, BuildTargetType, SourceFile
import "../core/compile-arguments" for LanguageStandard, OptimizationLevel, ResourceCompileArguments, SharedCompileArguments, TranslationUnitCompileArguments
import "../core/link-arguments" for LinkArguments, LinkTarget

class BuildEngineUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("BuildEngineUnitTests.Initialize_Success")
		this.Initialize_Success()
		System.print("BuildEngineUnitTests.Build_WindowsApplication")
		this.Build_WindowsApplication()
		System.print("BuildEngineUnitTests.Build_WindowsApplicationWithResource")
		this.Build_WindowsApplicationWithResource()
		System.print("BuildEngineUnitTests.Build_Executable")
		this.Build_Executable()
		System.print("BuildEngineUnitTests.Build_Library_PublicHeaderFiles")
		this.Build_Library_PublicHeaderFiles()
		System.print("BuildEngineUnitTests.Build_Library_MultipleFiles")
		this.Build_Library_MultipleFiles()
	}

	Initialize_Success() {
		SoupTest.initialize()

		var compiler = MockCompiler.new()
		var uut = BuildEngine.new(compiler)
	}

	Build_WindowsApplication() {
		// Setup the input build state
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Program"
		arguments.TargetType = BuildTargetType.WindowsApplication
		arguments.LanguageStandard = LanguageStandard.C17
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile.c"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)

		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.c")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile.mock.obj"),
		]
		expectedLinkArguments.LibraryFiles = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		// Verify expected compiler calls
		Assert.ListEqual([
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual([
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile.c"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[],
			result.LinkDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Program.exe"),
			],
			result.RuntimeDependencies)
	}

	Build_WindowsApplicationWithResource() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Program"
		arguments.TargetType = BuildTargetType.WindowsApplication
		arguments.LanguageStandard = LanguageStandard.C17
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile.c"),
		]
		arguments.ResourceFile = Path.new("Resources.rc")
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Resource File Compile: ./Resources.rc",
				"INFO: Generate Compile Operation: ./TestFile.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.c")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		expectedCompileArguments.ResourceFile = ResourceCompileArguments.new()
		expectedCompileArguments.ResourceFile.SourceFile = Path.new("Resources.rc")
		expectedCompileArguments.ResourceFile.TargetFile = Path.new("obj/Resources.mock.res")

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/Resources.mock.res"),
			Path.new("obj/TestFile.mock.obj"),
		]
		expectedLinkArguments.LibraryFiles = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile.c"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[],
			result.LinkDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Program.exe"),
			],
			result.RuntimeDependencies)
	}

	Build_Executable() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Program"
		arguments.TargetType = BuildTargetType.Executable
		arguments.LanguageStandard = LanguageStandard.C17
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile.c"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.c")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.Executable
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
				Path.new("obj/TestFile.mock.obj"),
		]
		expectedLinkArguments.LibraryFiles = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile.c"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[],
			result.LinkDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Program.exe"),
			],
			result.RuntimeDependencies)
	}

	Build_Library_PublicHeaderFiles() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"copy": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/copy.exe"
					}
				}
			},
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Library"
		arguments.TargetType = BuildTargetType.StaticLibrary
		arguments.LanguageStandard = LanguageStandard.C17
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile1.c"),
		]
		arguments.PublicHeaderFiles = [
			Path.new("TestFile1.h"),
			Path.new("TestFile2.h"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.Size
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.LinkDependencies = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile1.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Setup Public Headers",
				"INFO: Generate Copy Header: ./TestFile1.h",
				"INFO: Generate Copy Header: ./TestFile2.h",
			],
			SoupTest.logs)

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.Size
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.IncludeDirectories = [
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
		]

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit1Arguments.SourceFile = Path.new("TestFile1.c")
		expectedTranslationUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnit1Arguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
				Path.new("obj/TestFile1.mock.obj"),
		]

		// Note: There is no need to send along the static libraries for a static library linking
		expectedLinkArguments.LibraryFiles = []

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile1.c"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
			BuildOperation.new(
				"MakeDir [./include/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./include/",
				],
				[],
				[
					Path.new("./include/"),
				]),
			BuildOperation.new(
				"Copy [C:/source/TestFile1.h] -> [./include/TestFile1.h]",
				Path.new("C:/target/"),
				Path.new("/TARGET/copy.exe"),
				[
					"C:/source/TestFile1.h",
					"./include/TestFile1.h",
				],
				[
					Path.new("C:/source/TestFile1.h"),
				],
				[
					Path.new("include/TestFile1.h"),
				]),
			BuildOperation.new(
				"Copy [C:/source/TestFile2.h] -> [./include/TestFile2.h]",
				Path.new("C:/target/"),
				Path.new("/TARGET/copy.exe"),
				[
					"C:/source/TestFile2.h",
					"./include/TestFile2.h",
				],
				[
					Path.new("C:/source/TestFile2.h"),
				],
				[
					Path.new("include/TestFile2.h"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/Other1.mock.a"),
				Path.new("../Other2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}

	Build_Library_MultipleFiles() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Library"
		arguments.TargetType = BuildTargetType.StaticLibrary
		arguments.LanguageStandard = LanguageStandard.C17
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile1.c"),
			Path.new("TestFile2.c"),
			Path.new("TestFile3.c"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.Size
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.LinkDependencies = [
			Path.new("../Other/bin/Other1.mock.a"),
			Path.new("../Other2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile1.c",
				"INFO: Generate Compile Operation: ./TestFile2.c",
				"INFO: Generate Compile Operation: ./TestFile3.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			SoupTest.logs)

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.Size
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.IncludeDirectories = [
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
		]

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit1Arguments.SourceFile = Path.new("TestFile1.c")
		expectedTranslationUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")

		var expectedTranslationUnit2Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit2Arguments.SourceFile = Path.new("TestFile2.c")
		expectedTranslationUnit2Arguments.TargetFile = Path.new("obj/TestFile2.mock.obj")

		var expectedTranslationUnit3Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit3Arguments.SourceFile = Path.new("TestFile3.c")
		expectedTranslationUnit3Arguments.TargetFile = Path.new("obj/TestFile3.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnit1Arguments,
			expectedTranslationUnit2Arguments,
			expectedTranslationUnit3Arguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
				Path.new("obj/TestFile1.mock.obj"),
				Path.new("obj/TestFile2.mock.obj"),
				Path.new("obj/TestFile3.mock.obj"),
		]

		// Note: There is no need to send along the static libraries for a static library linking
		expectedLinkArguments.LibraryFiles = []

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile1.c"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile2.c"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile3.c"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/Other1.mock.a"),
				Path.new("../Other2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}
}