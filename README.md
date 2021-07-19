Covid-19 Drug Repurposing Project
=================================


Download/Install
----------------
To sync with Box, navigate to the root of this project and run

```
rclone sync . Box:FDA-Covid19-DR-project 
```

You need to have [rclone](https://rclone.org/box/) configured to be able to do this. Contact Neal if you need help with that. 

Data
----
Source data for this project is located under `data/source`, with different folders for the original sources of data.
- GNBR: Global Network of Biomedical Relationships, from [Zenodo](https://zenodo.org/record/3459420)
    - part-i-gene-disease-path-theme-distributions.txt
    - part-ii-dependency-paths-gene-disease-sorted.txt
- DrugBank