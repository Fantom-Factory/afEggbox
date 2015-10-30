
** Pod Repository
** ##############
** Alien-Factory's Pod Repository is a web application for storing and retrieving Fantom libraries, known as *pods*.
** 
** Anyone may browse and download public pods. Registered users may upload public pods, they may also keep private pods for personal use.
** 
** Pod Repositories may be queried by the 'fanr' command line tool and via a web interface. 
** 
** Pod Repository stores pods in a MongoDB database.
** 
** 
** 
** FANR Acceptance Tests
** *********************
** Acceptance tests for 'fanr' functionality:
** 
**  - [Fanr tests]`run:TestFanr#`
**
** 
**  
** Web Acceptance Tests
** ********************
** Acceptance tests for web site functionality:
** 
**  - [Fanr tests]`run:TestWeb#`
** 
** 
** 
** Core Acceptance Tests
** *********************
** Unit tests.
** 
**  - [FandocUri]`run:TestFandocUri#`
**  - [Smoke]`run:TestSmoke#`
**  - [Private Pod Versions]`run:TestPrivatePodVersions#`
** 
class RepoTests : RepoFixture { }
