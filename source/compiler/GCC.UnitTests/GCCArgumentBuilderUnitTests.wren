// <copyright file="GCCArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../GCC/GCCArgumentBuilder" for GCCArgumentBuilder
import "mwasplund|Soup.Build.Utils:./Path" for Path
import "../../Test/Assert" for Assert
import "../Core/CompileArguments" for LanguageStandard, OptimizationLevel, SharedCompileArguments, TranslationUnitCompileArguments

class GCCArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.C11, "-std=c11")
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.C17, "-std=c17")
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel_Disabled")
		this.BSCA_SingleArgument_OptimizationLevel_Disabled()
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Size, "-Os")
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Speed, "-O3")
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_EnableWarningsAsErrors")
		this.BSCA_SingleArgument_EnableWarningsAsErrors()
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_GenerateDebugInformation")
		this.BSCA_SingleArgument_GenerateDebugInformation()
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_IncludePaths")
		this.BSCA_SingleArgument_IncludePaths()
		System.print("GCCArgumentBuilderUnitTests.BSCA_SingleArgument_PreprocessorDefinitions")
		this.BSCA_SingleArgument_PreprocessorDefinitions()
		System.print("GCCArgumentBuilderUnitTests.BuildTranslationUnitCompilerArguments_Simple")
		this.BuildTranslationUnitCompilerArguments_Simple()
		System.print("GCCArgumentBuilderUnitTests.BuildAssemblyUnitCompilerArguments_Simple")
		this.BuildAssemblyUnitCompilerArguments_Simple()
	}

	// [Theory]
	// [InlineData(LanguageStandard.C11, "-std=c11")]
	// [InlineData(LanguageStandard.C17, "-std=c17")]
	BSCA_SingleArgument_LanguageStandard(
		standard,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = standard
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = GCCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			expectedFlag,
			"-O0",
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_OptimizationLevel_Disabled() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = GCCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-std=c17",
			"-O0",
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Theory]
	// [InlineData(OptimizationLevel.Size, "-Os")]
	// [InlineData(OptimizationLevel.Speed, "-O3")]
	BSCA_SingleArgument_OptimizationLevel(
		level,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = level

		var actualArguments = GCCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-std=c17",
			expectedFlag,
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_EnableWarningsAsErrors() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = OptimizationLevel.None
		arguments.EnableWarningsAsErrors = true

		var actualArguments = GCCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-Werror",
			"-std=c17",
			"-O0",
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_GenerateDebugInformation() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = OptimizationLevel.None
		arguments.GenerateSourceDebugInfo = true

		var actualArguments = GCCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-g",
			"-std=c17",
			"-O0",
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_IncludePaths() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C11
		arguments.Optimize = OptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("C:/Files/SDK/"),
			Path.new("my files/")
		]

		var actualArguments = GCCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-std=c11",
			"-O0",
			"-I\"C:/Files/SDK/\"",
			"-I\"./my files/\"",
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_PreprocessorDefinitions() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C11
		arguments.Optimize = OptimizationLevel.None
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"VERSION=1"
		]

		var actualArguments = GCCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-std=c11",
			"-O0",
			"-DDEBUG",
			"-DVERSION=1",
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildTranslationUnitCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("file1.c")
		arguments.TargetFile = Path.new("file1.obj")

		var responseFile = Path.new("ResponseFile.txt")

		var actualArguments = GCCArgumentBuilder.BuildTranslationUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"./file1.c",
			"-o",
			"C:/target/file1.obj",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildAssemblyUnitCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")
		var sharedArguments = SharedCompileArguments.new()
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("file1.asm")
		arguments.TargetFile = Path.new("file1.o")

		var actualArguments = GCCArgumentBuilder.BuildAssemblyUnitCompilerArguments(
			targetRootDirectory,
			sharedArguments,
			arguments)

		var expectedArguments = [
			"-o",
			"C:/target/file1.o",
			"-c",
			"-g",
			"-W3",
			"./file1.asm",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}
