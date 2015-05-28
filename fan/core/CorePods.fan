using afBeanUtils

const class CorePods {
	private const Str[] corePodNames := "docIntro docLang docFanr docTools build compiler compilerDoc compilerJava compilerJs concurrent dom email fandoc fanr fansh flux fluxText fwt gfx inet obix sql syntax sys util web webfwt webmod wisp xml".split

	Bool isCorePod(Str podName) {
		corePodNames.any { it.equalsIgnoreCase(podName) }
	}

	// caters for Uri.scheme lower casing stuff!
	Str corePodName(Str podName) {
		corePodNames.find { it.equalsIgnoreCase(podName) } ?: throw ArgNotFoundErr("Could not find core pod '${podName}'", corePodNames)
	}
}

