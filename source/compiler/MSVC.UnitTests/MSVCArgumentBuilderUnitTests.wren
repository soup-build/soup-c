// <copyright file="MSVCArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../MSVC/MSVCArgumentBuilder" for MSVCArgumentBuilder
import "mwasplund|Soup.Build.Utils:./Path" for Path
import "../../Test/Assert" for Assert
import "../Core/CompileArguments" for LanguageStandard, OptimizationLevel, SharedCompileArguments, TranslationUnitCompileArguments

class MSVCArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.C11, "/std:c11")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.C17, "/std:c17")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel_Disabled")
		this.BSCA_SingleArgument_OptimizationLevel_Disabled()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Size, "/Os")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Speed, "/Ot")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_EnableWarningsAsErrors")
		this.BSCA_SingleArgument_EnableWarningsAsErrors()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_GenerateDebugInformation")
		this.BSCA_SingleArgument_GenerateDebugInformation()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_IncludePaths")
		this.BSCA_SingleArgument_IncludePaths()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_PreprocessorDefinitions")
		this.BSCA_SingleArgument_PreprocessorDefinitions()
		System.print("MSVCArgumentBuilderUnitTests.BuildTranslationUnitCompilerArguments_Simple")
		this.BuildTranslationUnitCompilerArguments_Simple()
		System.print("MSVCArgumentBuilderUnitTests.BuildAssemblyUnitCompilerArguments_Simple")
		this.BuildAssemblyUnitCompilerArguments_Simple()
	}

	// [Theory]
	// [InlineData(LanguageStandard.C11, "/std:c11")]
	// [InlineData(LanguageStandard.C17, "/std:c17")]
	BSCA_SingleArgument_LanguageStandard(
		standard,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = standard
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			expectedFlag,
			"/Od",
			"/X",
			"/RTC1",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_OptimizationLevel_Disabled() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c17",
			"/Od",
			"/X",
			"/RTC1",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Theory]
	// [InlineData(OptimizationLevel.Size, "/Os")]
	// [InlineData(OptimizationLevel.Speed, "/Ot")]
	BSCA_SingleArgument_OptimizationLevel(
		level,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = level

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c17",
			expectedFlag,
			"/X",
			"/RTC1",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_EnableWarningsAsErrors() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = OptimizationLevel.None
		arguments.EnableWarningsAsErrors = true

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/WX",
			"/W4",
			"/std:c17",
			"/Od",
			"/X",
			"/RTC1",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_GenerateDebugInformation() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.C17
		arguments.Optimize = OptimizationLevel.None
		arguments.GenerateSourceDebugInfo = true

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/Z7",
			"/W4",
			"/std:c17",
			"/Od",
			"/X",
			"/RTC1",
			"/MTd",
			"/bigobj",
			"/c",
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

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c11",
			"/Od",
			"/I\"C:/Files/SDK/\"",
			"/I\"./my files/\"",
			"/X",
			"/RTC1",
			"/MT",
			"/bigobj",
			"/c",
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

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c11",
			"/Od",
			"/DDEBUG",
			"/DVERSION=1",
			"/X",
			"/RTC1",
			"/MT",
			"/bigobj",
			"/c",
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

		var actualArguments = MSVCArgumentBuilder.BuildTranslationUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"./file1.c",
			"/Fo\"C:/target/file1.obj\"",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildAssemblyUnitCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")
		var sharedArguments = SharedCompileArguments.new()
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("file1.asm")
		arguments.TargetFile = Path.new("file1.obj")

		var actualArguments = MSVCArgumentBuilder.BuildAssemblyUnitCompilerArguments(
			targetRootDirectory,
			sharedArguments,
			arguments)

		var expectedArguments = [
			"/nologo",
			"/Fo\"C:/target/file1.obj\"",
			"/c",
			"/Z7",
			"/W3",
			"./file1.asm",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}
