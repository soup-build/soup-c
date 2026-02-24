// <copyright file="expand-source-task.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "Soup|Build.Utils:./glob" for Glob
import "Soup|Build.Utils:./path" for Path
import "Soup|Build.Utils:./list-extensions" for ListExtensions
import "Soup|Build.Utils:./map-extensions" for MapExtensions

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

		// Expand the source from all discovered files
		Soup.info("Expand Source")
		var filesystem = globalState["FileSystem"]
		var sourceFiles = ExpandSourceTask.DiscoverCompileFiles(filesystem, Path.new(), allowedPaths)

		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "Source"),
			sourceFiles)
	}

	static DiscoverCompileFiles(currentDirectory, workingDirectory, allowedPaths) {
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				var file = workingDirectory + Path.new(directoryEntity)
				Soup.info("Check File: %(file)")
				if (ExpandSourceTask.IsMatchAny(allowedPaths, file)) {
					files.add(ExpandSourceTask.CreateSourceInfo(file))
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					Soup.info("Found Directory: %(directory)")
					var subFiles = ExpandSourceTask.DiscoverCompileFiles(child.value, directory, allowedPaths)
					ListExtensions.Append(files, subFiles)
				}
			}
		}

		return files
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