﻿// <copyright file="build-engine.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>


import "soup" for Soup
import "Soup|Build.Utils:./shared-operations" for SharedOperations
import "Soup|Build.Utils:./path" for Path
import "Soup|Build.Utils:./set" for Set
import "./build-result" for BuildResult
import "./build-arguments" for BuildOptimizationLevel, BuildTargetType
import "./link-arguments" for LinkArguments, LinkTarget
import "./compile-arguments" for OptimizationLevel, ResourceCompileArguments, SharedCompileArguments, TranslationUnitCompileArguments

/// <summary>
/// The build engine
/// </summary>
class BuildEngine {
	construct new(compiler) {
		_compiler = compiler
	}

	/// <summary>
	/// Generate the required build operations for the requested build
	/// </summary>
	Execute(arguments) {
		var result = BuildResult.new()

		// Ensure the output directories exists as the first step
		result.BuildOperations.add(
			SharedOperations.CreateCreateDirectoryOperation(
				arguments.TargetRootDirectory,
				arguments.ObjectDirectory))
		result.BuildOperations.add(
			SharedOperations.CreateCreateDirectoryOperation(
				arguments.TargetRootDirectory,
				arguments.BinaryDirectory))

		// Perform the core compilation of the source files
		this.CoreCompile(arguments, result)

		// Link the final target after all of the compile graph is done
		this.CoreLink(arguments, result)

		// Copy previous runtime dependencies after linking has completed
		this.CopyRuntimeDependencies(arguments, result)

		// Copy public headers
		this.CopyPublicHeaders(arguments, result)

		return result
	}

	/// <summary>
	/// Compile the source files
	/// </summary>
	CoreCompile(arguments, result) {
		// Ensure there are actually files to build
		if (arguments.SourceFiles.count != 0 ||
			arguments.AssemblySourceFiles.count != 0) {
			// Setup the shared properties
			var compileArguments = SharedCompileArguments.new()
			compileArguments.Standard = arguments.LanguageStandard
			compileArguments.Optimize = this.ConvertBuildOptimizationLevel(arguments.OptimizationLevel)
			compileArguments.SourceRootDirectory = arguments.SourceRootDirectory
			compileArguments.TargetRootDirectory = arguments.TargetRootDirectory
			compileArguments.ObjectDirectory = arguments.ObjectDirectory
			compileArguments.IncludeDirectories = arguments.IncludeDirectories
			compileArguments.PreprocessorDefinitions = arguments.PreprocessorDefinitions
			compileArguments.GenerateSourceDebugInfo = arguments.GenerateSourceDebugInfo
			compileArguments.EnableWarningsAsErrors = arguments.EnableWarningsAsErrors
			compileArguments.DisabledWarnings = arguments.DisabledWarnings
			compileArguments.EnabledWarnings = arguments.EnabledWarnings
			compileArguments.CustomProperties = arguments.CustomProperties

			// Compile the resource file if present
			if (arguments.ResourceFile) {
				Soup.info("Generate Resource File Compile: %(arguments.ResourceFile)")

				var compiledResourceFile =
					arguments.ObjectDirectory +
					Path.new(arguments.ResourceFile.GetFileName())
				compiledResourceFile.SetFileExtension(_compiler.ResourceFileExtension)

				var compileResourceFileArguments = ResourceCompileArguments.new()
				compileResourceFileArguments.SourceFile = arguments.ResourceFile
				compileResourceFileArguments.TargetFile = compiledResourceFile

				// Add the resource file arguments to the shared build definition
				compileArguments.ResourceFile = compileResourceFileArguments
			}

			// Compile the individual translation units
			var compileImplementationUnits = []
			for (file in arguments.SourceFiles) {
				Soup.info("Generate Compile Operation: %(file)")

				var compileFileArguments = TranslationUnitCompileArguments.new()
				compileFileArguments.SourceFile = file
				compileFileArguments.TargetFile = arguments.ObjectDirectory + Path.new(file.GetFileName())
				compileFileArguments.TargetFile.SetFileExtension(_compiler.ObjectFileExtension)

				compileImplementationUnits.add(compileFileArguments)
			}

			compileArguments.ImplementationUnits = compileImplementationUnits

			// Compile the individual assembly units
			var compileAssemblyUnits = []
			for (file in arguments.AssemblySourceFiles) {
				Soup.info("Generate Compile Assembly Operation: %(file)")

				var compileFileArguments = TranslationUnitCompileArguments.new()
				compileFileArguments.SourceFile = file
				compileFileArguments.TargetFile = arguments.ObjectDirectory + Path.new(file.GetFileName())
				compileFileArguments.TargetFile.SetFileExtension(_compiler.ObjectFileExtension)

				compileAssemblyUnits.add(compileFileArguments)
			}

			compileArguments.AssemblyUnits = compileAssemblyUnits

			// Compile all source files as a single call
			var compileOperations = _compiler.CreateCompileOperations(compileArguments)
			for (operation in compileOperations) {
				result.BuildOperations.add(operation)
			}
		}
	}

	/// <summary>
	/// Link the library
	/// </summary>
	CoreLink(
		arguments,
		result) {
		Soup.info("CoreLink")

		var targetFile
		var implementationFile
		if (arguments.TargetType == BuildTargetType.StaticLibrary) {
			targetFile = arguments.BinaryDirectory +
				_compiler.CreateStaticLibraryFileName(arguments.TargetName)
		} else if (arguments.TargetType == BuildTargetType.DynamicLibrary) {
			targetFile = arguments.BinaryDirectory +
				Path.new(arguments.TargetName + "." + _compiler.DynamicLibraryFileExtension)
			implementationFile = arguments.BinaryDirectory +
				Path.new(arguments.TargetName + "." + _compiler.DynamicLibraryLinkFileExtension)
		} else if (arguments.TargetType == BuildTargetType.Executable ||
			arguments.TargetType == BuildTargetType.WindowsApplication) {
			targetFile = arguments.BinaryDirectory + 
				Path.new(arguments.TargetName + ".exe")
		} else {
			Fiber.abort("Unknown build target type.")
		}

		Soup.info("Linking target")

		var linkArguments = LinkArguments.new()
		linkArguments.TargetFile = targetFile
		linkArguments.TargetArchitecture = arguments.TargetArchitecture
		linkArguments.ImplementationFile = implementationFile
		linkArguments.TargetRootDirectory = arguments.TargetRootDirectory
		linkArguments.LibraryPaths = arguments.LibraryPaths
		linkArguments.GenerateSourceDebugInfo = arguments.GenerateSourceDebugInfo

		// Build up the set of object files
		var objectFiles = []

		// Add the resource file if present
		if (!(arguments.ResourceFile is Null)) {
			var compiledResourceFile =
				arguments.ObjectDirectory +
				Path.new(arguments.ResourceFile.GetFileName())
			compiledResourceFile.SetFileExtension(_compiler.ResourceFileExtension)

			objectFiles.add(compiledResourceFile)
		}

		// Add the implementation unit object files
		for (sourceFile in arguments.SourceFiles) {
			var objectFile = arguments.ObjectDirectory + Path.new(sourceFile.GetFileName())
			objectFile.SetFileExtension(_compiler.ObjectFileExtension)
			objectFiles.add(objectFile)
		}

		// Add the assembly unit object files
		for (sourceFile in arguments.AssemblySourceFiles) {
			var objectFile = arguments.ObjectDirectory + Path.new(sourceFile.GetFileName())
			objectFile.SetFileExtension(_compiler.ObjectFileExtension)
			objectFiles.add(objectFile)
		}

		linkArguments.ObjectFiles = objectFiles


		// Only resolve link libraries if not a library ourself
		if (arguments.TargetType != BuildTargetType.StaticLibrary) {
			linkArguments.ExternalLibraryFiles = arguments.PlatformLinkDependencies
			linkArguments.LibraryFiles = arguments.LinkDependencies
		}

		// Translate the target type into the link target
		// and determine what dependencies to inject into downstream builds
		if (arguments.TargetType == BuildTargetType.StaticLibrary) {
			linkArguments.TargetType = LinkTarget.StaticLibrary
			
			// Add the library as a link dependency and all recursive libraries
			// Ensure we link this library before the other dependencies
			result.LinkDependencies = [] + arguments.LinkDependencies
			if (objectFiles.count != 0) { 
				var absoluteTargetFile = linkArguments.TargetFile.HasRoot ?
					linkArguments.TargetFile :
					linkArguments.TargetRootDirectory + linkArguments.TargetFile
				result.LinkDependencies.insert(0, absoluteTargetFile)
			} else {
				Soup.info("Skipping link dependency target with no object files")
			}
		} else if (arguments.TargetType == BuildTargetType.DynamicLibrary) {
			linkArguments.TargetType = LinkTarget.DynamicLibrary

			// Add the DLL as a runtime dependency
			var absoluteTargetFile = linkArguments.TargetFile.HasRoot ?
				linkArguments.TargetFile :
				linkArguments.TargetRootDirectory + linkArguments.TargetFile
			result.RuntimeDependencies.add(absoluteTargetFile)

			// Clear out all previous link dependencies and replace with the 
			// single implementation library for the DLL
			// Ensure we link this library before the other dependencies
			var absoluteImplementationFile = linkArguments.ImplementationFile.HasRoot ?
				linkArguments.ImplementationFile :
				linkArguments.TargetRootDirectory + linkArguments.ImplementationFile
			result.LinkDependencies.insert(0, absoluteImplementationFile)

			// Set the targe file
			result.TargetFile = absoluteTargetFile
		} else if (arguments.TargetType == BuildTargetType.Executable) {
			linkArguments.TargetType = LinkTarget.Executable

			// Add the Executable as a runtime dependency
			var absoluteTargetFile = linkArguments.TargetFile.HasRoot ?
				linkArguments.TargetFile :
				linkArguments.TargetRootDirectory + linkArguments.TargetFile
			result.RuntimeDependencies.add(absoluteTargetFile)

			// All link dependencies stop here.

			// Set the targe file
			result.TargetFile = absoluteTargetFile
		} else if (arguments.TargetType == BuildTargetType.WindowsApplication) {
			linkArguments.TargetType = LinkTarget.WindowsApplication

			// Add the Executable as a runtime dependency
			var absoluteTargetFile = linkArguments.TargetFile.HasRoot ?
				linkArguments.TargetFile :
				linkArguments.TargetRootDirectory + linkArguments.TargetFile
			result.RuntimeDependencies.add(absoluteTargetFile)

			// All link dependencies stop here.

			// Set the targe file
			result.TargetFile = absoluteTargetFile
		} else {
			Fiber.abort("Unknown build target type.")
		}

		// Perform the link
		Soup.info("Generate Link Operation: %(linkArguments.TargetFile)")
		var linkOperation = _compiler.CreateLinkOperation(linkArguments)
		result.BuildOperations.add(linkOperation)

		// Pass along the link arguments for internal access
		result.InternalLinkDependencies = []
		result.InternalLinkDependencies = result.InternalLinkDependencies + arguments.LinkDependencies
		for (file in linkArguments.ObjectFiles) {
			result.InternalLinkDependencies.add(file)
		}
	}

	/// <summary>
	/// Copy runtime dependencies
	/// </summary>
	CopyRuntimeDependencies(arguments, result) {
		if (arguments.TargetType == BuildTargetType.Executable ||
			arguments.TargetType == BuildTargetType.WindowsApplication ||
			arguments.TargetType == BuildTargetType.DynamicLibrary) {
			for (source in arguments.RuntimeDependencies) {
				var target = arguments.BinaryDirectory + Path.new(source.GetFileName())
				var operation = SharedOperations.CreateCopyFileOperation(
					arguments.TargetRootDirectory,
					source,
					target)
				result.BuildOperations.add(operation)

				// Add the copied file as the new runtime dependency
				result.RuntimeDependencies.add(target)
			}
		} else {
			// Pass along all runtime dependencies in their original location
			for (source in arguments.RuntimeDependencies) {
				result.RuntimeDependencies.add(source)
			}
		}
	}

	/// <summary>
	/// Copy public headers
	/// </summary>
	CopyPublicHeaders(arguments, result) {
		if (arguments.PublicHeaderSets.count > 0) {
			Soup.info("Setup Public Headers")
			var includeDirectory = Path.new("include/")

			// Pass along the output include folder
			result.PublicInclude = arguments.TargetRootDirectory + includeDirectory

			var folderSet = Set.new()
			folderSet.add(includeDirectory)

			for (fileSet in arguments.PublicHeaderSets) {
				Soup.info("Copy Header Set: %(fileSet.Root)")
				var includeSetDirectory = includeDirectory
				if (!(fileSet.Target is Null)) {
					includeSetDirectory = includeSetDirectory + fileSet.Target
				}

				for (file in fileSet.Files) {
					// Track all unique sub folders
					folderSet.add(includeSetDirectory + file.GetParent())
					
					// Copy the script files to the output
					Soup.info("Generate Copy Header: %(file)")
					var operation = SharedOperations.CreateCopyFileOperation(
							arguments.TargetRootDirectory,
							arguments.SourceRootDirectory + fileSet.Root + file,
							includeSetDirectory + file)
							
						result.BuildOperations.add(operation)
				}
			}

			// Ensure the output directories exists
			for (folder in folderSet.list) {
				result.BuildOperations.add(
					SharedOperations.CreateCreateDirectoryOperation(
						arguments.TargetRootDirectory,
						folder))
			}
		}
	}

	BuildClosure(closure, file, partitionInterfaceDependencyLookup) {
		for (childFile in partitionInterfaceDependencyLookup[file.toString]) {
			closure.add(childFile)
			this.BuildClosure(closure, childFile, partitionInterfaceDependencyLookup)
		}
	}

	ConvertBuildOptimizationLevel(value) {
		if (value == BuildOptimizationLevel.None) {
			return OptimizationLevel.None
		} else if (value == BuildOptimizationLevel.Speed) {
			return OptimizationLevel.Speed
		} else if (value == BuildOptimizationLevel.Size) {
			return OptimizationLevel.Size
		} else {
			Fiber.abort("Unknown BuildOptimizationLevel.")
		}
	}
}
