// <copyright file="expand-source-task.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "soup|build-utils:./glob" for Glob
import "soup|build-utils:./path" for Path
import "soup|build-utils:./list-extensions" for ListExtensions
import "soup|build-utils:./map-extensions" for MapExtensions

/// <summary>
/// The expand source task that knows how to discover source files from the file system state
/// </summary>
class ExpandSourceTask is SoupTask {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [
		"BuildTask",
	] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [
		"RecipeBuildTask",
	] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState

		var buildTable = activeState["Build"]

		var allowedPaths = []
		if (buildTable.containsKey("KnownSource")) {
			// Fill in the info on existing source files
			allowedPaths = ListExtensions.ConvertToPathList(buildTable["KnownSource"])
		} else {
			// Default to matching all C files under the root
			allowedPaths.add(Path.new("./**/*.c"))
		}

		var excludePaths = []
		if (buildTable.containsKey("KnownSourceExclude")) {
			// Fill in the info on existing excluded files
			excludePaths = ListExtensions.ConvertToPathList(buildTable["KnownSourceExclude"])
		}

		// Expand the source from all discovered files
		Soup.info("Expand Source")
		var filesystem = globalState["FileSystem"]
		var sourceFiles = ExpandSourceTask.DiscoverCompileFiles(
			filesystem, Path.new(), allowedPaths, excludePaths)

		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "Source"),
			sourceFiles)
	}

	static DiscoverCompileFiles(
		currentDirectory, workingDirectory, allowedPaths, excludePaths) {
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				var file = workingDirectory + Path.new(directoryEntity)
				Soup.info("Check File: %(file)")
				if (ExpandSourceTask.ShouldInclude(allowedPaths, excludePaths, file)) {
					files.add(ExpandSourceTask.CreateSourceInfo(file))
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					Soup.info("Found Directory: %(directory)")
					var subFiles = ExpandSourceTask.DiscoverCompileFiles(
						child.value, directory, allowedPaths, excludePaths)
					ListExtensions.Append(files, subFiles)
				}
			}
		}

		return files
	}

	static ShouldInclude(allowedPaths, excludePaths, file) {
		if (ExpandSourceTask.IsMatchAny(allowedPaths, file)) {
			// If we matched included, check if there is an explicit exclude
			if (ExpandSourceTask.IsMatchAny(excludePaths, file)) {
				return false
			} else {
				return true
			}
		} else {
			return false
		}
	}

	static IsMatchAny(allowedPaths, file) {
		for (allowedPath in allowedPaths) {
			if (Glob.IsMatch(allowedPath, file)) {
				return true
			}
		}

		return false
	}

	static CreateSourceInfo(file) {
		Soup.info("Found Source File: %(file)")
		return file.toString
	}
}