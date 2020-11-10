use crate::{annotation::Annotation, specification::Format, Error};
use core::{fmt, str::FromStr};
use std::{
    collections::HashSet,
    path::{Path, PathBuf},
};
use url::Url;

pub type TargetSet = HashSet<Target>;

#[derive(Clone, Debug, PartialEq, PartialOrd, Ord, Eq, Hash)]
pub struct Target {
    pub path: TargetPath,
    pub format: Format,
}

impl Target {
    pub fn from_annotation(anno: &Annotation) -> Result<Self, Error> {
        let path = TargetPath::from_annotation(anno)?;
        Ok(Self {
            path,
            format: anno.format,
        })
    }
}

impl FromStr for Target {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Self {
            path: s.parse()?,
            format: Format::default(),
        })
    }
}

#[derive(Clone, Debug, PartialEq, PartialOrd, Ord, Eq, Hash)]
pub enum TargetPath {
    Url(Url),
    Path(PathBuf),
}

impl fmt::Display for TargetPath {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Url(url) => url.fmt(f),
            Self::Path(path) => path.display().fmt(f),
        }
    }
}

impl TargetPath {
    pub fn from_annotation(anno: &Annotation) -> Result<Self, Error> {
        let path = anno.target_path();

        if path.starts_with('/') {
            return Ok(Self::Path(path.into()));
        }

        if path.starts_with('.') {
            let path = anno.source()?.parent().unwrap().join(&path);
            let path = path.canonicalize()?;
            return Ok(Self::Path(path));
        }

        if path.contains("://") {
            let url = Url::parse(&path)?;
            return Ok(Self::Url(url));
        }

        let path = anno.resolve_file(Path::new(&path))?;
        Ok(Self::Path(path))
    }

    pub fn load(&self) -> Result<String, Error> {
        let mut contents = match self {
            Self::Url(url) => {
                let path = self.local();
                if !path.exists() {
                    std::fs::create_dir_all(path.parent().unwrap())?;

                    reqwest::blocking::Client::builder()
                        .build()?
                        .get(url.as_str())
                        .header("user-agent", "https://crates.io/crates/cargo-compliance")
                        .send()?
                        .error_for_status()?
                        .copy_to(&mut std::fs::File::create(&path)?)?;
                }
                std::fs::read_to_string(path)?
            }
            Self::Path(path) => std::fs::read_to_string(path)?,
        };

        // make sure the file has a newline
        if !contents.ends_with('\n') {
            contents.push('\n');
        }

        Ok(contents)
    }

    pub fn local(&self) -> PathBuf {
        match self {
            Self::Url(url) => {
                let mut path = std::env::current_dir().unwrap();
                path.push("specs");
                path.push(url.host_str().expect("url should have host"));
                path.extend(url.path_segments().expect("url should have path"));
                path.set_extension("txt");
                path
            }
            Self::Path(path) => path.clone(),
        }
    }
}

impl FromStr for TargetPath {
    type Err = Error;

    fn from_str(path: &str) -> Result<Self, Self::Err> {
        if path.contains("://") {
            let url = Url::parse(&path)?;
            return Ok(Self::Url(url));
        }

        let path = Path::new(path).canonicalize()?;
        Ok(Self::Path(path))
    }
}
