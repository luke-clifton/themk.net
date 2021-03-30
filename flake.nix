{
  description = "TheMK.net blog.";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.blog-themk-net = import ./. { nixpkgs = nixpkgs.outputs.legacyPackages.x86_64-linux; };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.blog-themk-net;

  };
}
