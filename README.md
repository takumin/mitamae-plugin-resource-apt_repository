# mitamae-plugin-resource-apt_repository

## Usage

```ruby
apt_repository 'Docker CE Repository' do
  path '/etc/apt/sources.list.d/docker-ce.sources'
  entry [
    {
      :uri           => ENV['APT_REPO_URL_DOCKER'] || 'https://download.docker.com/linux/ubuntu',
      :suite         => '###platform_codename###',
      :components    => ['stable'],
      :architectures => ['amd64'],
      :signed_by     => '/etc/apt/keyrings/docker-ce.asc',
    },
  ]
end
```

## Attributes

- `path`: Output file. A path ending in `.sources` is rendered in the deb822 format, anything else in the one-line format.
- `entry`: Array of repository entries.
  - `uri` (required): Repository URI such as `http://deb.debian.org/debian`, checked after the placeholders are expanded.
  - `suite` (required): Suite name.
  - `components`: Array of components.
  - `architectures`, `languages`, `targets`: Array of values.
  - `signed_by`: String or Array of keyring paths or fingerprints.
  - `pdiffs`, `allow_insecure`, `allow_weak`, `allow_downgrade_to_insecure`, `trusted`, `check_valid_until`, `check_date`: `true` or `false`.
  - `by_hash`: `true`, `false` or `'force'`.
  - `valid_until_min`, `valid_until_max`, `date_max_future`: Integer (seconds).
  - `inrelease_path`, `snapshot`: String.
  - `source`: Also emit `deb-src`.

  The options above are the ones of sources.list(5). They are rendered as `[arch=amd64,i386 signed-by=/path]` in the one-line format and as `Architectures: amd64 i386` / `Signed-By: /path` in the deb822 format. `nil` is the same as not set.
- `header` / `footer`: String or Array of lines placed around the entries.

`###platform_distrib###`, `###platform_release###`, `###platform_codename###`, `###platform_major_version###` and `###platform_minor_version###` in `uri` and `suite` are expanded from `/etc/os-release` or `/etc/lsb-release`.

In the deb822 format, entries that differ only in `suite` are merged into one stanza.
