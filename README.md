ModSecurity on docker
===

Build
---

```bash
docker build -t modsecurity .
```

Run
---

```bash
docker run -d --name modsecurity -p 80:80 modsecurity
```

Ressources
---

- http://bit.ly/2eX46Ks
- http://bit.ly/2hbSNPk
- http://bit.ly/2eXDQ2v
- http://bit.ly/2eXKnu3
- https://github.com/sysboss/Nginx_Mod_Security
- https://github.com/nodeintegration/nginx-modsecurity/
