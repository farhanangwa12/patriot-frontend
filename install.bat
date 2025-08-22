echo.

:: Move to frontend

echo [INFO] Creating Frontend Structure...

:: Frontend directories
mkdir public
mkdir public\assets
mkdir src
mkdir src\components
mkdir src\components\common
mkdir src\components\quiz
mkdir src\components\user
mkdir src\views
mkdir src\store
mkdir src\store\modules
mkdir src\router
mkdir src\services
mkdir src\types
mkdir src\styles
mkdir src\styles\components
mkdir src\utils

echo [INFO] Creating Frontend Empty Files...

:: Public files
(
echo ^<!DOCTYPE html^>
echo ^<html lang="id"^>
echo ^<head^>
echo   ^<meta charset="UTF-8"^>
echo   ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo   ^<title^>Seberapa Patriotkah Kamu?^</title^>
echo   ^<link rel="icon" href="/favicon.ico"^>
echo ^</head^>
echo ^<body^>
echo   ^<div id="app"^>^</div^>
echo   ^<script type="module" src="/src/main.ts"^>^</script^>
echo ^</body^>
echo ^</html^> 
) > public\index.html

:: Components - Common
echo. > src\components\common\Header.vue
echo. > src\components\common\Footer.vue
echo. > src\components\common\Loading.vue
echo. > src\components\common\Modal.vue
echo. > src\components\common\Button.vue
echo. > src\components\common\Input.vue

:: Components - Quiz
echo. > src\components\quiz\QuizStart.vue
echo. > src\components\quiz\QuizQuestion.vue
echo. > src\components\quiz\QuizProgress.vue
echo. > src\components\quiz\QuizResult.vue
echo. > src\components\quiz\QuizCard.vue
echo. > src\components\quiz\QuizTimer.vue

:: Components - User
echo. > src\components\user\UserForm.vue
echo. > src\components\user\UserProfile.vue
echo. > src\components\user\UserStats.vue

:: Views
echo. > src\views\Home.vue
echo. > src\views\Quiz.vue
echo. > src\views\Result.vue
echo. > src\views\About.vue
echo. > src\views\NotFound.vue

:: Store
echo. > src\store\index.ts
echo. > src\store\types.ts
echo. > src\store\modules\quiz.ts
echo. > src\store\modules\user.ts
echo. > src\store\modules\result.ts
echo. > src\store\modules\app.ts

:: Router
echo. > src\router\index.ts
echo. > src\router\guards.ts

:: Services
echo. > src\services\api.ts
echo. > src\services\quizService.ts
echo. > src\services\userService.ts
echo. > src\services\resultService.ts
echo. > src\services\httpClient.ts

:: Types
echo. > src\types\quiz.ts
echo. > src\types\user.ts
echo. > src\types\api.ts
echo. > src\types\common.ts

:: Styles
echo. > src\styles\main.scss
echo. > src\styles\variables.scss
echo. > src\styles\mixins.scss
echo. > src\styles\reset.scss
echo. > src\styles\utilities.scss
echo. > src\styles\components\quiz.scss
echo. > src\styles\components\common.scss
echo. > src\styles\components\user.scss
echo. > src\styles\components\layout.scss

:: Utils
echo. > src\utils\helpers.ts
echo. > src\utils\constants.ts
echo. > src\utils\validators.ts
echo. > src\utils\formatters.ts

:: Main files
echo. > src\App.vue
echo. > src\main.ts

:: Config files
(
echo {
echo   "name": "patriot-quiz-frontend",
echo   "version": "1.0.0",
echo   "type": "module",
echo   "scripts": {
echo     "dev": "vite",
echo     "build": "vue-tsc && vite build",
echo     "preview": "vite preview",
echo     "type-check": "vue-tsc --noEmit"
echo   },
echo   "dependencies": {
echo     "vue": "^3.3.8",
echo     "vue-router": "^4.2.5",
echo     "vuex": "^4.1.0",
echo     "axios": "^1.6.2",
echo     "sass": "^1.69.5"
echo   },
echo   "devDependencies": {
echo     "@vitejs/plugin-vue": "^4.5.0",
echo     "typescript": "^5.2.2",
echo     "vue-tsc": "^1.8.22",
echo     "vite": "^5.0.0"
echo   }
echo } 
) > package.json

:: TypeScript config
(
echo {
echo   "compilerOptions": {
echo     "target": "ES2020",
echo     "useDefineForClassFields": true,
echo     "lib": ["ES2020", "DOM", "DOM.Iterable"],
echo     "module": "ESNext",
echo     "skipLibCheck": true,
echo     "moduleResolution": "bundler",
echo     "allowImportingTsExtensions": true,
echo     "resolveJsonModule": true,
echo     "isolatedModules": true,
echo     "noEmit": true,
echo     "jsx": "preserve",
echo     "strict": true,
echo     "noUnusedLocals": true,
echo     "noUnusedParameters": true,
echo     "noFallthroughCasesInSwitch": true,
echo     "baseUrl": ".",
echo     "paths": {
echo       "@/*": ["src/*"]
echo     }
echo   },
echo   "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.tsx", "src/**/*.vue"],
echo   "exclude": ["node_modules"]
echo } 
)> tsconfig.json

:: Vite config
echo. > vite.config.ts

:: Environment template
echo VITE_API_URL=http://localhost:3000/api
echo VITE_APP_NAME=Patriot Quiz
echo VITE_APP_VERSION=1.0.0 > .env.example


echo Waitt....
npm install
echo [INFO] Frontend structure created successfully!
echo.


echo.
echo =============================================
echo    PROJECT STRUCTURE CREATED SUCCESSFULLY!
echo =============================================
echo.
echo 📁 Project: patriot-quiz/
echo 🔧 Backend: Express.js + PostgreSQL + OpenAI
echo 🎨 Frontend: Vue.js + TypeScript + SASS
echo 🐳 Docker: Ready for containerization
echo.
echo Next steps:
echo 1. cd patriot-quiz/backend && npm install
echo 2. cd ../frontend && npm install
echo 3. Configure .env files
echo 4. Start coding!
echo.
echo Happy coding! 🚀