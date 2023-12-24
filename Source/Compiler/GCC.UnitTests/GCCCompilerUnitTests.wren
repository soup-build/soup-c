// <copyright file="GCCCompilerUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../GCC/GCCCompiler" for GCCCompiler
import "mwasplund|Soup.Build.Utils:./Path" for Path
import "../../Test/Assert" for Assert
import "mwasplund|Soup.Build.Utils:./BuildOperation" for BuildOperation
import "../Core/LinkArguments" for LinkArguments, LinkTarget
import "../Core/CompileArguments" for LanguageStandard, OptimizationLevel,  SharedCompileArguments, ResourceCompileArguments, TranslationUnitCompileArguments

class GCCCompilerUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("GCCCompilerUnitTests.Initialize")
		this.Initialize()
		System.print("GCCCompilerUnitTests.Compile_Simple")
		this.Compile_Simple()
		System.print("GCCCompilerUnitTests.Compile_Resource")
		this.Compile_Resource()
		System.print("GCCCompilerUnitTests.LinkStaticLibrary_Simple")
		this.LinkStaticLibrary_Simple()
		System.print("GCCCompilerUnitTests.LinkExecutable_Simple")
		this.LinkExecutable_Simple()
		System.print("GCCCompilerUnitTests.LinkWindowsApplication_Simple")
		this.LinkWindowsApplication_Simple()
	}

	// [Fact]
	Initialize() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.cl.exe"),
			Path.new("C:/bin/mock.link.exe"),
			Path.new("C:/bin/mock.lib.exe"),
			Path.new("C:/bin/mock.rc.exe"),
			Path.new("C:/bin/mock.ml.exe"))
		Assert.Equal("GCC", uut.Name)
		Assert.Equal("o", uut.ObjectFileExtension)
		Assert.Equal(Path.new("libTest.a"), uut.CreateStaticLibraryFileName("Test"))
		Assert.Equal("so", uut.DynamicLibraryFileExtension)
		Assert.Equal("res", uut.ResourceFileExtension)
	}

	// [Fact]
	Compile_Simple(){
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.cl.exe"),
			Path.new("C:/bin/mock.link.exe"),
			Path.new("C:/bin/mock.lib.exe"),
			Path.new("C:/bin/mock.rc.exe"),
			Path.new("C:/bin/mock.ml.exe"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")

		var translationUnitArguments = TranslationUnitCompileArguments.new()
		translationUnitArguments.SourceFile = Path.new("File.c")
		translationUnitArguments.TargetFile = Path.new("obj/File.obj")

		arguments.ImplementationUnits = [
			translationUnitArguments,
		]

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/SharedCompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/SharedCompileArguments.rsp",
					"-std=c11 -O0 -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File.c",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.cl.exe"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"./File.c",
					"-o",
					"C:/target/obj/File.obj",
				],
				[
					Path.new("File.c"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
				],
				[
					Path.new("C:/target/obj/File.obj"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Resource() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.cl.exe"),
			Path.new("C:/bin/mock.link.exe"),
			Path.new("C:/bin/mock.lib.exe"),
			Path.new("C:/bin/mock.rc.exe"),
			Path.new("C:/bin/mock.ml.exe"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")
		arguments.IncludeDirectories = [
			Path.new("Includes"),
		]
		arguments.PreprocessorDefinitions = [
			"DEBUG"
		]
		arguments.ResourceFile = ResourceCompileArguments.new(
			Path.new("Resources.rc"),
			Path.new("obj/Resources.res"))

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/SharedCompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/SharedCompileArguments.rsp",
					"-std=c11 -O0 -I\"./Includes\" -DDEBUG -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./Resources.rc",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.rc.exe"),
				[
					"-D_UNICODE",
					"-DUNICODE",
					"-l\"0x0409\"",
					"-I\"./Includes\"",
					"-o",
					"C:/target/obj/Resources.res",
					"./Resources.rc",
				],
				[
					Path.new("Resources.rc"),
					Path.new("C:/target/fake_file"),
				],
				[
					Path.new("C:/target/obj/Resources.res"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	LinkStaticLibrary_Simple() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.cl.exe"),
			Path.new("C:/bin/mock.link.exe"),
			Path.new("C:/bin/mock.lib.exe"),
			Path.new("C:/bin/mock.rc.exe"),
			Path.new("C:/bin/mock.ml.exe"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.a")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Library.mock.a",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.lib.exe"),
			[
				"-o",
				"./Library.mock.a",
				"./File.mock.obj",
			],
			[
				Path.new("File.mock.obj"),
			],
			[
				Path.new("C:/target/Library.mock.a"),
			])

		Assert.Equal(expected, result)
	}

	// [Fact]
	LinkExecutable_Simple() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.cl.exe"),
			Path.new("C:/bin/mock.link.exe"),
			Path.new("C:/bin/mock.lib.exe"),
			Path.new("C:/bin/mock.rc.exe"),
			Path.new("C:/bin/mock.ml.exe"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.Executable
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Something.exe")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Something.exe",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.link.exe"),
			[
				"-o",
				"./Something.exe",
				"./Library.mock.a",
				"./File.mock.obj",
			],
			[
				Path.new("Library.mock.a"),
				Path.new("File.mock.obj"),
			],
			[
				Path.new("C:/target/Something.exe"),
			])

		Assert.Equal(expected, result)
	}

	// [Fact]
	LinkWindowsApplication_Simple() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.cl.exe"),
			Path.new("C:/bin/mock.link.exe"),
			Path.new("C:/bin/mock.lib.exe"),
			Path.new("C:/bin/mock.rc.exe"),
			Path.new("C:/bin/mock.ml.exe"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.WindowsApplication
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Something.exe")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Something.exe",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.link.exe"),
			[
				"-o",
				"./Something.exe",
				"./Library.mock.a",
				"./File.mock.obj",
			],
			[
				Path.new("Library.mock.a"),
				Path.new("File.mock.obj"),
			],
			[
				Path.new("C:/target/Something.exe"),
			])

		Assert.Equal(expected, result)
	}
}
