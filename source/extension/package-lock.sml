Version: 6
Closure: {
	Wren: {
		C: { Version: './', Build: '0', Tool: '0' }
		'Soup|C': { Version: './', Build: '0', Tool: '0' }
		'Soup|Build.Utils': { Version: 0.9.1, Digest: 'sha256:65d8d0415f37a762ab0e9d0e5597610bc9d84c5e595cf2bf7e81cf3701cb5ffc', Build: '0', Tool: '0' }
		'Soup|C.Compiler': { Version: 0.5.0, Digest: 'sha256:11d990dad89efd82b83853c661de5c9260943b1130684676aff426794f74ee65', Build: '0', Tool: '0' }
		'Soup|C.Compiler.Clang': { Version: 0.5.0, Digest: 'sha256:0bcaa667dafc87f81b37be7f2ba32c5e638306274820ea8a08f7847543a957bc', Build: '0', Tool: '0' }
		'Soup|C.Compiler.GCC': { Version: 0.5.0, Digest: 'sha256:db7fb588b9f0f89b8db2166d251744c9a0eceb5134668a047aac781b0402f237', Build: '0', Tool: '0' }
		'Soup|C.Compiler.MSVC': { Version: 0.5.1, Digest: 'sha256:cedb01797a41a09a36e53d8920b3948c3250c943adcabb284cac6b578e90868f', Build: '0', Tool: '0' }
	}
}
Builds: {
	'0': {
		Wren: {
			'Soup|Wren': {
				Version: 0.5.4
				Digest: 'sha256:bbd0bdf404cfdb4ec3c398e29072b10a32951b9be7c1e6b724d13ac17d703b03'
				Artifacts: {
					Linux: 'sha256:5186e1532f6bad21295d3f4b11fdd49d19ebd91090fe475ea294b8f92b8cc964'
					Windows: 'sha256:426eb660e2e4f306b933d8a15fcadd9cfd5f7ee33b10e89c259da8335aef94c6'
				}
			}
		}
	}
}
Tools: {
	'0': {
		'C++': {
			'mwasplund|copy': {
				Version: 1.2.0
				Digest: 'sha256:4fd4849523e50e06930c6f97088827feeae6b52ad6020bfbda578f37084234bf'
				Artifacts: {
					Linux: 'sha256:60a9a23a9eea9c4c767b4c4dc4b5738017ff2592426de7215c3b8b14e439d832'
					Windows: 'sha256:b7b38403b6cf786d484b6ca68b1b8158197ef8546dd73f5c6a681d0ed3b75f1c'
				}
			}
			'mwasplund|mkdir': {
				Version: 1.2.0
				Digest: 'sha256:14bdf971c3a955c79982a7e18d248516c4a70bd6b139abb286f44d80d5e91ac2'
				Artifacts: {
					Linux: 'sha256:c3962d814e1c716454b803753f8304af8bb85b6260f6802992781fb8ae4c5365'
					Windows: 'sha256:ca96d73393fb552312190c3392490e3c61e2e4e0e5e50e411d5924fd27e34eba'
				}
			}
		}
	}
}