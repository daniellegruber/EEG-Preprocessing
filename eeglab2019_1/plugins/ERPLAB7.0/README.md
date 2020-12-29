
ERPLAB Toolbox is a free, open-source Matlab package for analyzing ERP data.  It is tightly integrated with [EEGLAB Toolbox](http://sccn.ucsd.edu/eeglab/), extending EEGLAB’s capabilities to provide robust, industrial-strength tools for ERP processing, visualization, and analysis.  A graphical user interface makes it easy for beginners to learn, and Matlab scripting provides enormous power for intermediate and advanced users.



## ERPLAB v7.0.0

<p align="center" >
  <a href="https://github.com/lucklab/erplab/releases/download/7.0.0/erplab7.0.0.zip"><img src="https://cloud.githubusercontent.com/assets/8988119/8532773/873b2af0-23e5-11e5-9869-c900726713a2.jpg">
<br/>

  <img src="https://cloud.githubusercontent.com/assets/5808953/8663301/1ff9a26a-297e-11e5-9e15-a7085569058f.png" width=300px >
 </a>
</p>

To install ERPLAB v7.0.0, download the zip file (linked above), unzip and place the folder in the 'plugins' folder of your existing [EEGLAB](https://sccn.ucsd.edu/eeglab/download.php) installation (e.g.  `/Users/Steve/Documents/MATLAB/eeglab13_6_4b/plugins/erplab7.0.0/`). More [installation help can be found here](https://github.com/lucklab/erplab/wiki/Installation).

To run ERPLAB, ensure that the correct EEGLAB folder is in your current Matlab path, and run **eeglab** as a command from the Matlab Command Window. [Find our tutorial here.](https://github.com/lucklab/erplab/wiki/Tutorial)

We encourage most users to use this latest major version.

---

## ERPLAB compatibility

We anticipate that ERPLAB will work with most recent OSs, Matlab versions and EEGLAB versions.

- We recommend a 64 bit OS, 64 bit Matlab, and at least 4 GB RAM. Most modern computers meet this.
- The Matlab Signal Processing Toolbox is required
  - Entering in the command `ver` in the Command Window will produce a list of installed toolboxes. Check this list to see whether the Signal Processing Toolbox is installed
- EEGLAB v12 or later is recommended. EEGLAB v11 is not recommended.

Find installation help [here](http://erpinfo.org/erplab)

### ERPLAB compatibility table

Here is a list of some confirmed-working environments for ERPLAB.

**ERPLAB v7.0.0*

| **OS** | **Matlab** | **EEGLAB** | Working? |
| --- | --- | --- | --- |
| Mac OS X 10.11.5 'El Capitan' | Matlab R2015a | EEGLAB v13.5.4b | ✓ |
| MacOS 10.12 'Sierra' | Matlab R2016a | EEGLAB v13.5.4b | ✓  |
| Mac OS 10.13.5 'High Sierra' | Matlab R2015a | EEGLAB v14.1.2 | ✓ |
| Mac OS 10.13.5 'High Sierra' | Matlab R2018a | EEGLAB v14.1.2 | ✓ (with Matlab update) |
| Windows 7 | Matlab R2014a | EEGLAB v13.5.4b | ✓ |
| Windows 8.1 | Matlab R2014a | EEGLAB v13.5.4b | ✓ |
| Windows 10 | Matlab R2015a | EEGLAB v13.5.4b | ✓ |
| Ubuntu 14.04 LTS | Matlab R2014a | EEGLAB v13.5.4b | ✓ |

* - For Matlab R2018a, the [Matlab Update 3 fixes a crucial Matlab bug](https://www.mathworks.com/downloads/web_downloads/download_update?release=R2018a&s_tid=ebrg_R2018a_2_1757132&s_tid=mwa_osa_a).

<br/>
<br/>



## ERPLAB v7.0.0 Release Notes

- Updated tools for [pre-processing continuous EEG](https://github.com/lucklab/erplab/wiki/Continuous-EEG-Preprocessing), including functions for
   - deleting time segments
   - shifting event codes
   - selective electrode interpolation

- Crucial [compatibility fixes](https://github.com/lucklab/erplab/issues/56) to allow running in R2017b and later, while still being backwards-compatible with older versions of Matlab. No more yellow warnings about NARGCHK in R2016a or later.




### ERPLAB v6.1.4
Some additions and minor bugfixes, including:
- Removing channels can now avoid deleting all channel location information
- More channel location tools
- Measurement Window GUI now fits on a smaller screen
- Improvements in 'Preprocess Continuous EEG' options
- Fixed a bug where the number of loaded erpsets would be mistakenly taken to be zero
- Improved Current-Source-Density compatibility
- Replaced the error 'Quack' noise with a beep, and replaced some error pictures.

### ERPLAB v6.1.3
Minor bugfixes, including:
- Cleaned up the Measurement Viewer text and options
- Measurement Viewer helper text now only shown when relevant

### ERPLAB v6.1.2
Minor bugfixes, including:
- Fixed BDF Library url-link in BDF-Visualizer
- Swapped artifact and user-flag display in BDF-Visualizer

### ERPLAB v6.1.1
Minor bugfixes, including:
- Shift Event Codes GUI fix - now doesn't crash on launch.
- Adopted [Major].[Minor].[Patch] version numbers, this being v6.1.1, with backward-compatible file loading. Note - from v6.0, we no longer indicate the file type usage in the version number, and this is now always taken to be 1.

### ERPLAB v6.0 Release Notes

With ERPLAB v6.0, we include a variety of new features, user-interface improvements, bug-fixes, and improvements to existing functions. Among these, we have:


### - Current Source Density Tool

EEG or ERP data can be used to compute an estimate of the Current Source Density (CSD). We include new functions to take data loaded in ERPLAB (either EEG or ERP) and compute the CSD data. We use CSD methods from Jürgen Kayser (from the [CSD Toolbox](http://psychophysiology.cpmc.columbia.edu/Software/CSDtoolbox/)).

These tools can be found in the new 'ERPLAB -> Data Transformations' menu. A new ERPLAB dataset is generated, with CSD data in the place of EEG/ERP data.

Find [CSD documentation here](https://github.com/lucklab/erplab/wiki/Current-Source-Density-(CSD)-tool)


### - Fractional peak measurement can now be offset (post-peak) as well as onset (pre-peak)

In the ERP Measurement tool, ERPLAB can record measurements of local peaks and the time of a fractional peak, like 50% peak. Previously, this fractional peak measurement was taken from the 'onset' of the peak, before the peak. In v6.0, ERPLAB also has an option to measure the fractional peak 'offset', the 50% peak value after the peak.



### - ERPLAB documentation on GitHub

For more easy editing, ERPLAB documentation has been moved to a [wiki here](https://github.com/lucklab/erplab/wiki).



----
### Bug Fixes

[Bug fixes as detailed here](https://github.com/lucklab/erplab/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aclosed)
